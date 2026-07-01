# iOS Testing Status

Last updated: 2026-07-01

GitHub issue: https://github.com/scwlkr/UQIQ/issues/6

Status: resolved on this Mac on 2026-07-01.

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
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 2
godot --headless --path . --script res://scripts/verify_local_profile.gd
godot --headless --path . --script res://scripts/verify_issue_3.gd
godot --headless --path . --script res://scripts/verify_issue_4.gd
godot --headless --path . --script res://scripts/verify_issue_5_desktop_smoke.gd
```

Passing smoke summary:

```text
Issue #5 desktop smoke passed: 128 completions, 122 replays, 128 Score Roastcards, 23 save/load checks, 1 Dur spend(s), 1 Dur recovery event(s), 20 stability cycles.
```

Physical device is now available:

```sh
xcrun devicectl list devices
xcodebuild -project /tmp/uqiq-ios-current/UQIQ.xcodeproj -scheme UQIQ -showdestinations
```

Result includes:

```text
17 Hoe Max ... 9820C039-3903-5542-9D4A-388ED65AEFDE ... connected ... iPhone 17 Pro Max (iPhone18,2) ... physical
{ platform:iOS, arch:arm64, id:00008150-001435EA1480401C, name:17 Hoe Max }
```

Fresh Godot iOS export still returns the known generic archive provisioning error, but it does produce the current Xcode project and packed app content:

```sh
rm -rf /tmp/uqiq-ios-current
mkdir -p /tmp/uqiq-ios-current
godot --headless --path . --export-debug iOS /tmp/uqiq-ios-current/UQIQ.ipa
```

Known Godot generic archive result:

```text
"UQIQ" requires a provisioning profile.
```

Direct physical-device Xcode build succeeds with automatic signing:

```sh
xcodebuild -project /tmp/uqiq-ios-current/UQIQ.xcodeproj -scheme UQIQ -sdk iphoneos -configuration Debug -destination 'platform=iOS,id=00008150-001435EA1480401C' build -allowProvisioningUpdates -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=QP9SJRTA44 CODE_SIGN_STYLE=Automatic
```

Result:

```text
Signing Identity: Apple Development: Shane Walker (79A6A93QV3)
Provisioning Profile: iOS Team Provisioning Profile: * (02720632-77c8-4918-9d15-5ee9a5c85e14)
** BUILD SUCCEEDED **
```

Clean physical install, launch, screenshot, and focused smoke play succeeded. The reinstall reset the on-device local container before the smoke path.

```sh
xcrun devicectl device uninstall app --device 9820C039-3903-5542-9D4A-388ED65AEFDE com.scwlkr.uqiq
xcrun devicectl device install app --device 9820C039-3903-5542-9D4A-388ED65AEFDE /Users/shanewalker/Library/Developer/Xcode/DerivedData/UQIQ-bbluxcjdadfkhkgndqtdpwcmtjwx/Build/Products/Debug-iphoneos/UQIQ.app
xcrun devicectl device process launch --device 9820C039-3903-5542-9D4A-388ED65AEFDE com.scwlkr.uqiq
xcrun devicectl device capture screenshot --device 9820C039-3903-5542-9D4A-388ED65AEFDE --destination /tmp/uqiq-issue6-clean-level-list.png
```

Clean launch showed `UQIQ 100`, `Dur 3/3`, and `Level 01 unlocked`.

Focused smoke path was completed through iPhone Mirroring on the physical phone:

- Level 1: tapped `WRONG`.
- Level 2: selected `Move: WRONG`, then `Drop on: Truth Box`.
- Level 3: entered `nothing`, then submitted.
- Level 4: selected center cell `r2c2`, then submitted.
- Level 5: used `Flash`, `Hide`, entered `SUN`, `MOON`, `DUR`, then submitted.
- Level 6: selected `Draw: ramp to cup`, then `Release Ball`.

Final physical-device result:

```text
Levels 1-6 completed
Local Profile: UQIQ 156 | Dur 3/3 | Level 07 unlocked
```

After the six-Level smoke path, save/load after app restart was confirmed:

```sh
xcrun devicectl device process terminate --device 9820C039-3903-5542-9D4A-388ED65AEFDE --pid 1100
xcrun devicectl device process launch --device 9820C039-3903-5542-9D4A-388ED65AEFDE --json-output /tmp/uqiq-issue6-restart-launch.json com.scwlkr.uqiq
```

The relaunch JSON reported process identifier `1235`. The relaunched app was inspected through iPhone Mirroring and still showed `UQIQ 156`, `Dur 3/3`, and `Level 07 unlocked`.

Post-restart process stability check:

```sh
xcrun devicectl device process awaitTermination --device 9820C039-3903-5542-9D4A-388ED65AEFDE --pid 1235 --timeout 60 --json-output /tmp/uqiq-issue6-restart-await-termination.json
```

Result: `awaitTermination` timed out after 60 seconds, so UQIQ did not terminate after restart during the watch window.

## Simulator Status

The iOS 27 simulator runtime is installed and a phone simulator boots.

UQIQ can build for simulator only when forced to `x86_64`:

```sh
xcodebuild -project /tmp/uqiq-ios/UQIQ.xcodeproj -scheme UQIQ -sdk iphonesimulator -configuration Debug -destination 'platform=iOS Simulator,id=386B1A12-F8D3-4358-BF58-14FE7CB7E03E' build CODE_SIGNING_ALLOWED=NO ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO EXCLUDED_ARCHS=arm64
```

That build succeeds, but it cannot install on the iOS 27 simulator because the simulator runs `arm64` only and the Godot 4.7 official simulator `libgodot.a` present here is `x86_64`.

Physical iPhone is the valid proof path for issue #6, and it is now proven.

## Current Blocker

None for issue #6.

Known note: Godot's generic iOS archive command still returns the provisioning-profile error above. The direct Xcode physical-device build, install, launch, and smoke path are green with automatic signing.
