#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
EXPORT_DIR="${UQIQ_IOS_EXPORT_DIR:-/tmp/uqiq-ios-quick}"
DERIVED_DATA_DIR="${UQIQ_DERIVED_DATA_DIR:-$EXPORT_DIR/DerivedData}"
TEAM_ID="${UQIQ_DEVELOPMENT_TEAM:-QP9SJRTA44}"
BUNDLE_ID="${UQIQ_BUNDLE_ID:-com.wlkrlabs.uqiq}"
SCHEME="${UQIQ_XCODE_SCHEME:-UQIQ}"
CONFIGURATION="${UQIQ_XCODE_CONFIGURATION:-Debug}"
VERIFY_SCRIPT="${UQIQ_VERIFY_SCRIPT:-res://scripts/verify_issue_43_tactile_tap_logic.gd}"
MARKETING_VERSION="${UQIQ_SHORT_VERSION:-}"
BUILD_NUMBER="${UQIQ_BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"
DEVICE_ID="${UQIQ_DEVICE_ID:-}"
XCODE_DEVICE_ID="${UQIQ_XCODE_DEVICE_ID:-}"
LAUNCH_ENV_JSON="${UQIQ_LAUNCH_ENV_JSON:-}"
PLAYTEST_LEVEL="${UQIQ_PLAYTEST_LEVEL:-}"
SCREENSHOT_PATH="${UQIQ_SCREENSHOT_PATH:-$EXPORT_DIR/uqiq-phone-$BUILD_NUMBER.png}"


log() {
	printf '[uqiq-deploy] %s\n' "$*"
}


die() {
	printf '[uqiq-deploy] ERROR: %s\n' "$*" >&2
	exit 1
}


require_tool() {
	command -v "$1" >/dev/null 2>&1 || die "Missing required tool: $1"
}


short_version_from_export_preset() {
	awk -F= '$1 == "application/short_version" { gsub(/"/, "", $2); print $2; exit }' "$PROJECT_ROOT/export_presets.cfg"
}


write_device_json() {
	xcrun devicectl list devices --json-output "$EXPORT_DIR/devices.json" >/dev/null
}


resolve_device_ids() {
	write_device_json

	if [[ -z "$DEVICE_ID" && -z "$XCODE_DEVICE_ID" ]]; then
		DEVICE_ID="$(
			jq -r '[.result.devices[]
				| select(.hardwareProperties.reality == "physical")
				| select(.connectionProperties.tunnelState == "connected")
			][0].identifier // empty' "$EXPORT_DIR/devices.json"
		)"
		XCODE_DEVICE_ID="$(
			jq -r '[.result.devices[]
				| select(.hardwareProperties.reality == "physical")
				| select(.connectionProperties.tunnelState == "connected")
			][0].hardwareProperties.udid // empty' "$EXPORT_DIR/devices.json"
		)"
	elif [[ -n "$DEVICE_ID" && -z "$XCODE_DEVICE_ID" ]]; then
		XCODE_DEVICE_ID="$(
			jq -r --arg device_id "$DEVICE_ID" '[.result.devices[]
				| select(.identifier == $device_id)
			][0].hardwareProperties.udid // empty' "$EXPORT_DIR/devices.json"
		)"
	elif [[ -z "$DEVICE_ID" && -n "$XCODE_DEVICE_ID" ]]; then
		DEVICE_ID="$(
			jq -r --arg xcode_id "$XCODE_DEVICE_ID" '[.result.devices[]
				| select(.hardwareProperties.udid == $xcode_id)
			][0].identifier // empty' "$EXPORT_DIR/devices.json"
		)"
	fi

	[[ -n "$DEVICE_ID" ]] || die "No connected physical iPhone found. Pair once in Xcode, enable Connect via Network, unlock the phone, then rerun."
	[[ -n "$XCODE_DEVICE_ID" ]] || die "Could not resolve Xcode hardware UDID for devicectl device $DEVICE_ID."

	local state
	state="$(
		jq -r --arg device_id "$DEVICE_ID" '[.result.devices[]
			| select(.identifier == $device_id)
		][0].connectionProperties.tunnelState // empty' "$EXPORT_DIR/devices.json"
	)"
	[[ "$state" == "connected" ]] || die "Device $DEVICE_ID is not connected according to devicectl. Current state: ${state:-unknown}."
}


run_targeted_verifier() {
	if [[ -z "$VERIFY_SCRIPT" ]]; then
		log "Skipping targeted verifier because UQIQ_VERIFY_SCRIPT is empty."
		return
	fi

	log "Running targeted verifier: $VERIFY_SCRIPT"
	"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --script "$VERIFY_SCRIPT"
}


export_xcode_project() {
	log "Exporting temporary iOS project to $EXPORT_DIR"
	rm -rf "$EXPORT_DIR"
	mkdir -p "$EXPORT_DIR"

	set +e
	"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-debug iOS "$EXPORT_DIR/UQIQ.ipa" 2>&1 | tee "$EXPORT_DIR/godot-export.log"
	local export_status=${PIPESTATUS[0]}
	set -e

	if [[ ! -d "$EXPORT_DIR/UQIQ.xcodeproj" ]]; then
		die "Godot did not create $EXPORT_DIR/UQIQ.xcodeproj. See $EXPORT_DIR/godot-export.log."
	fi

	if [[ "$export_status" -ne 0 ]]; then
		log "Godot export exited $export_status after generating the Xcode project; continuing with manual Xcode signing."
	fi
}


build_app() {
	local app_path="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION-iphoneos/UQIQ.app"
	rm -rf "$DERIVED_DATA_DIR"

	log "Building $SCHEME for device $XCODE_DEVICE_ID as $MARKETING_VERSION ($BUILD_NUMBER)"
	xcodebuild \
		-project "$EXPORT_DIR/UQIQ.xcodeproj" \
		-scheme "$SCHEME" \
		-sdk iphoneos \
		-configuration "$CONFIGURATION" \
		-destination "platform=iOS,id=$XCODE_DEVICE_ID" \
		-derivedDataPath "$DERIVED_DATA_DIR" \
		build \
		-allowProvisioningUpdates \
		-allowProvisioningDeviceRegistration \
		DEVELOPMENT_TEAM="$TEAM_ID" \
		CODE_SIGN_STYLE=Automatic \
		MARKETING_VERSION="$MARKETING_VERSION" \
		CURRENT_PROJECT_VERSION="$BUILD_NUMBER" 2>&1 | tee "$EXPORT_DIR/xcodebuild.log"

	[[ -d "$app_path" ]] || die "Build succeeded but app bundle was not found at $app_path."
	printf '%s\n' "$app_path" > "$EXPORT_DIR/app-path.txt"
}


install_launch_capture() {
	local app_path
	app_path="$(cat "$EXPORT_DIR/app-path.txt")"

	log "Installing $app_path to devicectl device $DEVICE_ID"
	xcrun devicectl device install app --device "$DEVICE_ID" "$app_path" 2>&1 | tee "$EXPORT_DIR/install.log"

	log "Installed app metadata"
	xcrun devicectl device info apps --device "$DEVICE_ID" --bundle-id "$BUNDLE_ID" 2>&1 | tee "$EXPORT_DIR/app-info.log"

	local launch_command=(
		xcrun devicectl device process launch
		--device "$DEVICE_ID"
		--terminate-existing
	)
	if [[ -z "$LAUNCH_ENV_JSON" && -n "$PLAYTEST_LEVEL" ]]; then
		[[ "$PLAYTEST_LEVEL" =~ ^[0-9]+$ ]] || die "UQIQ_PLAYTEST_LEVEL must be numeric."
		LAUNCH_ENV_JSON="{\"UQIQ_PLAYTEST_LEVEL\":\"$PLAYTEST_LEVEL\"}"
	fi
	if [[ -n "$LAUNCH_ENV_JSON" ]]; then
		launch_command+=(--environment-variables "$LAUNCH_ENV_JSON")
	fi
	launch_command+=("$BUNDLE_ID")

	log "Launching $BUNDLE_ID"
	if ! "${launch_command[@]}" 2>&1 | tee "$EXPORT_DIR/launch.log"; then
		die "Launch failed. If the log says Locked, unlock the phone and rerun this script."
	fi

	xcrun devicectl device orientation set --device "$DEVICE_ID" portrait >/dev/null 2>&1 || log "Could not force portrait orientation; continuing."

	log "Capturing screenshot proof to $SCREENSHOT_PATH"
	xcrun devicectl device capture screenshot --device "$DEVICE_ID" --destination "$SCREENSHOT_PATH" 2>&1 | tee "$EXPORT_DIR/screenshot.log"
	log "Done. Screenshot: $SCREENSHOT_PATH"
}


main() {
	require_tool "$GODOT_BIN"
	require_tool xcrun
	require_tool xcodebuild
	require_tool jq

	if [[ -z "$MARKETING_VERSION" ]]; then
		MARKETING_VERSION="$(short_version_from_export_preset)"
	fi
	[[ -n "$MARKETING_VERSION" ]] || die "Could not resolve MARKETING_VERSION from export_presets.cfg."

	mkdir -p "$EXPORT_DIR"
	resolve_device_ids
	local device_name
	device_name="$(
		jq -r --arg device_id "$DEVICE_ID" '[.result.devices[]
			| select(.identifier == $device_id)
		][0].deviceProperties.name // "unknown device"' "$EXPORT_DIR/devices.json"
	)"
	log "Using $device_name: devicectl=$DEVICE_ID xcode=$XCODE_DEVICE_ID"

	run_targeted_verifier
	git -C "$PROJECT_ROOT" diff --check
	export_xcode_project
	build_app
	install_launch_capture
}


main "$@"
