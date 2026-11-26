# UQIQ

UQIQ is a mobile puzzle game for iOS and Android.

The name is pronounced like **“you Q I Q”**. It is a self-aware fake-IQ game built around logic traps, physics puzzles, word problems, pattern tests, memory challenges, trick questions, and chaotic problem-solving levels.

UQIQ is not a real IQ test.
It is worse: it judges you for fun.

## Core Idea

UQIQ is a problem-solving game where each level tests a different kind of thinking.

Some levels may be simple text-based questions.
Some may involve patterns, timing, memory, or logic.
Some may use physics, drawing, gravity, collisions, and open-ended solutions.

The goal is to make the player feel smart, dumb, confused, and determined all at the same time.

## Platforms

UQIQ is being built for:

* iOS
* Android

Primary testing will happen on iOS, but the project should stay compatible with Android from the beginning.

## Tech Direction

The current plan is to build UQIQ with **Godot**.

Godot is being considered because the game may include physics-based puzzle levels, while still supporting simpler word/problem/pattern levels inside the same project.

Possible backend support later:

* Accounts
* Saved progress
* Daily challenges
* Leaderboards
* Shared scores
* User-created levels

## Level Types

Possible UQIQ challenge types:

* Physics puzzles
* Word problems
* Logic traps
* Pattern puzzles
* Memory challenges
* Trick questions
* Timed challenges
* Chaos rounds

## Tone

UQIQ should feel:

* Clever
* Funny
* Slightly judgmental
* Memey
* Clean
* Fast
* Addictive
* Not too serious

The app can use IQ language as part of the joke, but it should never claim to be a real scientific or clinical IQ test.

## Status

Early concept phase.

This repo is for building the first playable version of UQIQ.

## Run Locally

Requirements:

* Godot 4.x

Open/run:

1. Open Godot 4.x.
2. Click **Import**.
3. Select this repo's `project.godot`.
4. Open the imported project.
5. Press **Run Project**.

The boot skeleton starts at the Level List, loads the default Pack Level Files from `content/levels/`, opens unlocked Levels, and routes completion to a Score Roastcard.

Headless import/run checks:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 2
```

## Local Save Reset

Runtime progress is stored locally at:

```text
user://uqiq_local_profile_v1.json
```

Godot maps that to the app user-data folder. On macOS development builds, the usual path is:

```text
~/Library/Application Support/Godot/app_userdata/UQIQ/uqiq_local_profile_v1.json
```

Reset local progress before a clean vertical-slice run:

```sh
rm -f "$HOME/Library/Application Support/Godot/app_userdata/UQIQ/uqiq_local_profile_v1.json"
```

## Desktop Smoke

Manual smoke:

1. Reset the local save.
2. Run the project in desktop Godot.
3. Play Levels 1-6 end to end.
4. Replay one completed Level.
5. Spend a Dur Token on an unlocked incomplete Level, then complete that DUR'D Level and confirm the token returns.
6. Keep the app open for 10 minutes and confirm no crash.

## iOS Export / Physical iPhone Proof

Physical iPhone proof requires Apple signing access, Xcode, and a connected iPhone trusted by macOS.

Current setup/proof status is tracked in [`docs/IOS_TESTING_STATUS.md`](docs/IOS_TESTING_STATUS.md).

Quick phone deploy loop:

```sh
scripts/deploy_phone.sh
```

The script requires Godot, Xcode command-line tools, `xcrun`, `xcodebuild`, and `jq`. It runs a targeted verifier, exports a temporary iOS project under `/tmp/uqiq-ios-quick`, builds with Xcode automatic signing, installs with `devicectl`, launches UQIQ, and captures screenshot proof. It does not commit generated iOS export artifacts.

One-time wireless setup:

1. Plug the iPhone into the Mac.
2. Open Xcode's Devices window and enable network connection for the phone.
3. Trust the Mac, keep Developer Mode enabled, unlock the phone, then confirm `xcrun devicectl list devices` still shows the physical iPhone after unplugging.

Useful overrides:

```sh
UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_43_tactile_tap_logic.gd scripts/deploy_phone.sh
UQIQ_PLAYTEST_LEVEL=19 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_45_tactile_memory_flash.gd scripts/deploy_phone.sh
UQIQ_PLAYTEST_LEVEL=3 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_66_goalposts_rearrange.gd scripts/deploy_phone.sh
UQIQ_PLAYTEST_LEVEL=4 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_67_gravity_handles_rearrange.gd scripts/deploy_phone.sh
UQIQ_PLAYTEST_LEVEL=5 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_68_cup_blinks_reveal_freehand.gd scripts/deploy_phone.sh
UQIQ_PLAYTEST_LEVEL=9 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_47_tactile_text_trap.gd scripts/deploy_phone.sh
UQIQ_PLAYTEST_UNLOCK_ALL=1 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_48_debug_playtest_all.gd scripts/deploy_phone.sh
UQIQ_DEVICE_ID=9820C039-3903-5542-9D4A-388ED65AEFDE scripts/deploy_phone.sh
UQIQ_XCODE_DEVICE_ID=00008150-001435EA1480401C scripts/deploy_phone.sh
UQIQ_BUILD_NUMBER=3 scripts/deploy_phone.sh
UQIQ_SCREENSHOT_DELAY=0 scripts/deploy_phone.sh
```

If launch fails with a locked-device error, unlock the iPhone and rerun the same command.

Godot/Xcode path:

1. Install Godot iOS export templates for the same Godot 4.x version used locally.
2. Open Godot, import `project.godot`, then open **Project > Export**.
3. Use the committed **iOS** export preset in `export_presets.cfg`.
4. Set Apple signing team, provisioning profile, and required icons/placeholders in the preset.
5. Export the iOS project.
6. Open the exported project in Xcode.
7. Select the physical iPhone as the run destination.
8. Confirm signing resolves cleanly, then build/install/run.
9. On device, reset/reinstall if needed, then complete the six-Level smoke path and confirm save/load after app restart.

If signing, Apple Developer access, Xcode setup, or physical device access is unavailable, do not mark iPhone proof complete. Open/link a blocked GitHub issue with the exact missing Apple account, signing, device, or Xcode step needed.
