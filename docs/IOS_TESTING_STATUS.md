# iOS Testing Status

Last updated: 2026-07-01

Active GitHub issue: https://github.com/scwlkr/UQIQ/issues/6

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

Godot iOS export now reaches Xcode archive and fails only on provisioning:

```sh
godot --headless --path . --export-debug iOS /tmp/uqiq-ios/UQIQ.ipa
```

Current result:

```text
"UQIQ" requires a provisioning profile.
```

Physical-device Xcode build currently fails because the iPhone is not an available destination:

```sh
xcodebuild -project /tmp/uqiq-ios/UQIQ.xcodeproj -scheme UQIQ -sdk iphoneos -configuration Debug -destination 'platform=iOS,id=00008150-001435EA1480401C' build -allowProvisioningUpdates -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=QP9SJRTA44 CODE_SIGN_STYLE=Automatic
```

Current result:

```text
Unable to find a destination matching: platform=iOS,id=00008150-001435EA1480401C
```

`xcrun devicectl list devices` currently sees the physical iPhone, but it is unavailable:

```text
17 Hoe Max ... unavailable ... iPhone18,2
```

Xcode's destination chooser also lists only My Mac and simulators. It does not list the physical iPhone as a runnable device yet.

## Simulator Status

The iOS 27 simulator runtime is installed and a phone simulator boots.

UQIQ can build for simulator only when forced to `x86_64`:

```sh
xcodebuild -project /tmp/uqiq-ios/UQIQ.xcodeproj -scheme UQIQ -sdk iphonesimulator -configuration Debug -destination 'platform=iOS Simulator,id=386B1A12-F8D3-4358-BF58-14FE7CB7E03E' build CODE_SIGNING_ALLOWED=NO ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO EXCLUDED_ARCHS=arm64
```

That build succeeds, but it cannot install on the iOS 27 simulator because the simulator runs `arm64` only and the Godot 4.7 official simulator `libgodot.a` present here is `x86_64`.

Physical iPhone remains the valid proof path for issue #6.

## Current Blocker

The only remaining blocker is physical iPhone availability and provisioning.

The iPhone is still updating/downloading. Do not continue physical-device proof until Shane explicitly says the iPhone is ready.

When ready, the iPhone must be:

- Connected by USB if possible.
- Unlocked and on the Home Screen.
- Trusted by this Mac if prompted.
- In Developer Mode if iOS prompts for it.
- Visible in Xcode's destination chooser or `xcodebuild -showdestinations`.

## Next Commands When iPhone Is Ready

Regenerate the temporary iOS export project if `/tmp/uqiq-ios` is gone:

```sh
rm -rf /tmp/uqiq-ios
mkdir -p /tmp/uqiq-ios
godot --headless --path . --export-debug iOS /tmp/uqiq-ios/UQIQ.ipa
```

Then check the device:

```sh
xcrun devicectl list devices
xcodebuild -project /tmp/uqiq-ios/UQIQ.xcodeproj -scheme UQIQ -showdestinations
```

Then build with automatic provisioning and device registration:

```sh
xcodebuild -project /tmp/uqiq-ios/UQIQ.xcodeproj -scheme UQIQ -sdk iphoneos -configuration Debug -destination 'platform=iOS,id=00008150-001435EA1480401C' build -allowProvisioningUpdates -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=QP9SJRTA44 CODE_SIGN_STYLE=Automatic
```

Done when Xcode creates/downloads a provisioning profile, installs UQIQ on the physical iPhone, and UQIQ launches there without crashing during the focused smoke path.
