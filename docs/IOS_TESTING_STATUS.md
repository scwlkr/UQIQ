# iOS Testing Status

Last updated: 2026-07-02

Active GitHub issue: https://github.com/scwlkr/UQIQ/issues/25

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

Physical-device Xcode build now succeeds for `com.wlkrlabs.uqiq` against `17 Hoe Max`:

```sh
xcodebuild -project /tmp/uqiq-ios-wlkrlabs/UQIQ.xcodeproj -scheme UQIQ -sdk iphoneos -configuration Debug -destination 'platform=iOS,id=00008150-001435EA1480401C' build -allowProvisioningUpdates -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=QP9SJRTA44 CODE_SIGN_STYLE=Automatic
```

Current result:

```text
** BUILD SUCCEEDED **
Signing Identity: Apple Development: Shane Walker (79A6A93QV3)
Provisioning Profile: iOS Team Provisioning Profile: * (UUID 02720632-77c8-4918-9d15-5ee9a5c85e14)
Profile application identifier: QP9SJRTA44.*
```

`xcrun devicectl list devices` and `xcodebuild -showdestinations` now see the physical iPhone:

```text
17 Hoe Max ... connected ... iPhone18,2
{ platform:iOS, arch:arm64, id:00008150-001435EA1480401C, name:17 Hoe Max }
```

The app installs and launches on the physical iPhone:

```sh
xcrun devicectl device install app --device 9820C039-3903-5542-9D4A-388ED65AEFDE /Users/shanewalker/Library/Developer/Xcode/DerivedData/UQIQ-dkgmgzzhwncdyobemcmwqexzypys/Build/Products/Debug-iphoneos/UQIQ.app
xcrun devicectl device process launch --device 9820C039-3903-5542-9D4A-388ED65AEFDE --terminate-existing --environment-variables '{"UQIQ_DEVICE_SMOKE":"1"}' com.wlkrlabs.uqiq
xcrun devicectl device orientation set --device 9820C039-3903-5542-9D4A-388ED65AEFDE portrait
xcrun devicectl device capture screenshot --device 9820C039-3903-5542-9D4A-388ED65AEFDE --destination /tmp/uqiq-issue-25-wlkrlabs-device-smoke-portrait-current.png
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

Physical iPhone proof is complete for the development-signed `com.wlkrlabs.uqiq` bundle.

## Distribution Status

The Release export preset is now internally set for App Store distribution:

```text
application/code_sign_identity_release="Apple Distribution"
application/export_method_release=0
application/bundle_identifier="com.wlkrlabs.uqiq"
```

`godot --headless --path . --export-release iOS /tmp/uqiq-ios-release-wlkrlabs/UQIQ.ipa` now generates:

```text
method = app-store
teamID = QP9SJRTA44
provisioningProfiles.com.wlkrlabs.uqiq = ""
```

The direct Godot archive still fails because the generated project has an `Apple Distribution` identity while automatic signing starts from development settings:

```text
UQIQ is automatically signed for development, but a conflicting code signing identity Apple Distribution has been manually specified.
```

The generated Xcode project can still produce a valid App Store Connect IPA by clearing the archive-time identity override and letting export-time automatic signing use Xcode cloud-managed distribution signing:

```sh
xcodebuild -project /tmp/uqiq-ios-release-wlkrlabs/UQIQ.xcodeproj -scheme UQIQ -sdk iphoneos -configuration Release -destination generic/platform=iOS archive -allowProvisioningUpdates DEVELOPMENT_TEAM=QP9SJRTA44 CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="" -archivePath /tmp/uqiq-ios-release-wlkrlabs/UQIQ-auto.xcarchive
xcodebuild -exportArchive -archivePath /tmp/uqiq-ios-release-wlkrlabs/UQIQ-auto.xcarchive -exportPath /tmp/uqiq-ios-release-wlkrlabs/exported -exportOptionsPlist /tmp/uqiq-ios-release-wlkrlabs/UQIQ/export_options.plist -allowProvisioningUpdates
```

Current result:

```text
** ARCHIVE SUCCEEDED **
** EXPORT SUCCEEDED **
Exported IPA: /tmp/uqiq-ios-release-wlkrlabs/exported/UQIQ.ipa
Signing Identity: Apple Distribution: Shane Walker (QP9SJRTA44)
Provisioning Profile: iOS Team Store Provisioning Profile: com.wlkrlabs.uqiq
Entitlements: beta-reports-active=true, get-task-allow=false
Info.plist privacy strings: camera/microphone/photo library are non-empty and state no v1.0 use.
```

Local signing/App Store Connect inventory:

```text
security find-identity -v -p codesigning
Apple Development: Shane Walker (79A6A93QV3)
No local Apple Distribution identity found; export used cloud-managed distribution signing.

~/Library/Developer/Xcode/UserData/Provisioning Profiles/02720632-77c8-4918-9d15-5ee9a5c85e14.mobileprovision
iOS Team Provisioning Profile: *
Application identifier: QP9SJRTA44.*
Provisioned device: 00008150-001435EA1480401C

xcrun altool --list-providers
Either JWT (--api-issuer and --api-key) or username and app password authentication is required.
```

Internal-TestFlight-only upload was attempted with `destination=upload` and `testFlightInternalTestingOnly=true`:

```text
Uploading "UQIQ.ipa" is complete.
Uploaded package is processing.
Upload succeeded.
```

## Internal TestFlight Status

App Store Connect now shows UQIQ `0.1.0 (1)` in TestFlight:

```text
Build: 1
Status: Ready to Test
Expires: 90 days
Group: Internal Smoke
```

Internal TestFlight group setup:

```text
Group: Internal Smoke
Type: Internal Group
Automatic distribution: enabled
Builds: 1
Tester: Shane Walker <shane.caleb.walker@gmail.com>
Tester status: Invited
```

Proof screenshots:

```text
/tmp/uqiq-testflight-poll-1.png
/tmp/uqiq-testflight-internal-group-ready.png
/tmp/uqiq-testflight-tester-added-modal.png
```

No external TestFlight or public App Review path has been started.

## Current Blocker

The remaining release blocker requires scwlkr to accept the internal TestFlight invite, install UQIQ `0.1.0 (1)` on a physical iPhone, and launch it once for proof.

## Next Commands After Apple Access

```sh
rm -rf /tmp/uqiq-ios-release-wlkrlabs
mkdir -p /tmp/uqiq-ios-release-wlkrlabs
godot --headless --path . --export-release iOS /tmp/uqiq-ios-release-wlkrlabs/UQIQ.ipa
```

If a replacement build is needed, retry the generated project manually and upload as an internal-TestFlight-only proof build:

```sh
xcodebuild -project /tmp/uqiq-ios-release-wlkrlabs/UQIQ.xcodeproj -scheme UQIQ -sdk iphoneos -configuration Release -destination generic/platform=iOS archive -allowProvisioningUpdates DEVELOPMENT_TEAM=QP9SJRTA44 CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="" -archivePath /tmp/uqiq-ios-release-wlkrlabs/UQIQ-auto.xcarchive
xcodebuild -exportArchive -archivePath /tmp/uqiq-ios-release-wlkrlabs/UQIQ-auto.xcarchive -exportPath /tmp/uqiq-ios-release-wlkrlabs/exported -exportOptionsPlist /tmp/uqiq-ios-release-wlkrlabs/UQIQ/export_options.plist -allowProvisioningUpdates
cp /tmp/uqiq-ios-release-wlkrlabs/exported/ExportOptions.plist /tmp/uqiq-upload-export-options.plist
plutil -replace destination -string upload /tmp/uqiq-upload-export-options.plist
plutil -replace testFlightInternalTestingOnly -bool true /tmp/uqiq-upload-export-options.plist
xcodebuild -exportArchive -archivePath /tmp/uqiq-ios-release-wlkrlabs/UQIQ-auto.xcarchive -exportPath /tmp/uqiq-ios-release-wlkrlabs/upload -exportOptionsPlist /tmp/uqiq-upload-export-options.plist -allowProvisioningUpdates
```
