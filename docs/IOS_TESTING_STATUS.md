# iOS Testing Status

Last updated: 2026-07-01

Active GitHub issue: https://github.com/scwlkr/UQIQ/issues/24

## Mac Tooling

The Mac-side iOS toolchain is set up for the current beta path:

- Selected Xcode: `/Users/shanewalker/Downloads/Xcode-beta.app/Contents/Developer`
- Xcode version: `Xcode 27.0`, build `27A5209h`
- Command Line Tools package: `com.apple.pkg.CLTools_Executables` version `27.0.0.0.1781811268`
- iOS SDK: `iphoneos27.0`
- iOS simulator SDK: `iphonesimulator27.0`
- iOS 27 simulator runtime: installed, `24A5370g`
- Xcode beta Metal Toolchain: installed, build `27A5209h`
- Apple Development signing identity: `Apple Development: Shane Walker (79A6A93QV3)`
- Apple team id in `export_presets.cfg`: `QP9SJRTA44`
- Godot iOS export template path:
  `/Users/shanewalker/Library/Application Support/Godot/export_templates/4.7.stable/ios.zip`

## Repo Export Setup

Commit `c333ac5` on branch `codex/issue-6-ios-export-setup` prepared the committed iOS export setup:

- Added Apple team id to the iOS export preset.
- Added iOS minimum target `15.0`.
- Added required iOS icon PNG placeholders and import metadata.
- Wired the iOS export preset icon slots to committed assets.

## Current Verification

Desktop Godot smoke remains passing:

```sh
godot --headless --path . --script res://scripts/verify_issue_5_desktop_smoke.gd
```

Expected passing summary:

```text
Issue #5 desktop smoke passed: 128 completions, 122 replays, 128 Score Roastcards, 23 save/load checks, 1 Dur spend(s), 1 Dur recovery event(s), 20 stability cycles.
```

Godot iOS export regenerates the temporary Xcode project and still fails at the generic archive step unless signing build settings are supplied manually:

```sh
godot --headless --path . --export-debug iOS /tmp/uqiq-ios/UQIQ.ipa
```

Current generic archive result:

```text
"UQIQ" requires a provisioning profile.
```

Physical-device Xcode build now succeeds against `17 Hoe Max`:

```sh
xcodebuild -project /tmp/uqiq-ios/UQIQ.xcodeproj -scheme UQIQ -sdk iphoneos -configuration Debug -destination 'platform=iOS,id=00008150-001435EA1480401C' build -allowProvisioningUpdates -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=QP9SJRTA44 CODE_SIGN_STYLE=Automatic
```

Current result:

```text
** BUILD SUCCEEDED **
Signing Identity: Apple Development: Shane Walker (79A6A93QV3)
Provisioning Profile: iOS Team Provisioning Profile: *
```

`xcrun devicectl list devices` and `xcodebuild -showdestinations` now see the physical iPhone:

```text
17 Hoe Max ... connected ... iPhone18,2
{ platform:iOS, arch:arm64, id:00008150-001435EA1480401C, name:17 Hoe Max }
```

The app installs and launches on the physical iPhone:

```sh
xcrun devicectl device install app --device 9820C039-3903-5542-9D4A-388ED65AEFDE /Users/shanewalker/Library/Developer/Xcode/DerivedData/UQIQ-gzplululhoslqicnydwkeixwffki/Build/Products/Debug-iphoneos/UQIQ.app
xcrun devicectl device process launch --device 9820C039-3903-5542-9D4A-388ED65AEFDE --terminate-existing --environment-variables '{"UQIQ_DEVICE_SMOKE":"1"}' com.scwlkr.uqiq
xcrun devicectl device orientation set --device 9820C039-3903-5542-9D4A-388ED65AEFDE portrait
xcrun devicectl device capture screenshot --device 9820C039-3903-5542-9D4A-388ED65AEFDE --destination /tmp/uqiq-issue-24-device-smoke-portrait.png
```

Device smoke result visible in the screenshot:

```text
Device Smoke Passed
Loaded 60 specs and selected Levels 01-03
Level List rendered on device
Play -> Score Roastcard path passed through Level 03
Local Profile save/load preserved Level 01-03 state
1 save/load check(s), 1 Dur spend(s), 1 Dur recovery event(s)
No launch crash observed before/after smoke path
```

## Simulator Status

The iOS 27 simulator runtime is installed and a phone simulator boots.

UQIQ can build for simulator only when forced to `x86_64`:

```sh
xcodebuild -project /tmp/uqiq-ios/UQIQ.xcodeproj -scheme UQIQ -sdk iphonesimulator -configuration Debug -destination 'platform=iOS Simulator,id=386B1A12-F8D3-4358-BF58-14FE7CB7E03E' build CODE_SIGNING_ALLOWED=NO ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO EXCLUDED_ARCHS=arm64
```

That build succeeds, but it cannot install on the iOS 27 simulator because the simulator runs `arm64` only and the Godot 4.7 official simulator `libgodot.a` present here is `x86_64`.

Physical iPhone proof for issue #24 is complete.

## Current Blocker

The remaining release blocker is distribution proof: create a release archive, export/upload for TestFlight, and complete any required App Store Connect setup.

## Next Commands

```sh
rm -rf /tmp/uqiq-ios
mkdir -p /tmp/uqiq-ios
godot --headless --path . --export-release iOS /tmp/uqiq-ios/UQIQ.ipa
```

If Godot's generic archive still fails, retry the generated project manually with explicit signing settings:

```sh
xcodebuild -project /tmp/uqiq-ios/UQIQ.xcodeproj -scheme UQIQ -sdk iphoneos -configuration Release -destination generic/platform=iOS archive -allowProvisioningUpdates DEVELOPMENT_TEAM=QP9SJRTA44 CODE_SIGN_STYLE=Automatic -archivePath /tmp/uqiq-ios/UQIQ.xcarchive
```

Then export/upload through Xcode/App Store Connect tooling once distribution signing resolves.
