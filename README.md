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

## Vertical Slice Verification

Run from a clean save:

```sh
rm -f "$HOME/Library/Application Support/Godot/app_userdata/UQIQ/uqiq_local_profile_v1.json"
godot --headless --path . --script res://scripts/verify_local_profile.gd
godot --headless --path . --script res://scripts/verify_issue_3.gd
godot --headless --path . --script res://scripts/verify_issue_4.gd
godot --headless --path . --script res://scripts/verify_issue_5_desktop_smoke.gd
godot --headless --path . --script res://scripts/verify_issue_7_pack_1_smoke.gd
godot --headless --path . --script res://scripts/verify_issue_8_pack_2_specs.gd
godot --headless --path . --script res://scripts/verify_issue_10_pack_2_smoke.gd
godot --headless --path . --script res://scripts/verify_issue_11_pack_3_specs.gd
godot --headless --path . --script res://scripts/verify_issue_11_pack_3_smoke.gd
godot --headless --path . --script res://scripts/verify_issue_12_pack_4_specs.gd
godot --headless --path . --script res://scripts/verify_issue_12_pack_4_smoke.gd
godot --headless --path . --script res://scripts/verify_issue_13_pack_5_specs.gd
godot --headless --path . --script res://scripts/verify_issue_13_pack_5_smoke.gd
godot --headless --path . --script res://scripts/verify_issue_16_pack_6_specs.gd
godot --headless --path . --script res://scripts/verify_issue_16_pack_6_smoke.gd
godot --headless --path . --script res://scripts/verify_issue_19_scoring.gd
godot --headless --path . --script res://scripts/verify_issue_20_feedback.gd
godot --headless --path . --script res://scripts/verify_issue_21_judge_transitions.gd
godot --headless --path . --script res://scripts/verify_issue_22_physics_draw.gd
godot --headless --path . --script res://scripts/verify_issue_23_ui_readability.gd
godot --headless --path . --script res://scripts/verify_issue_38_long_screen_fit.gd
godot --headless --path . --script res://scripts/verify_issue_40_interaction_core.gd
godot --headless --path . --script res://scripts/verify_issue_41_pack_6_direct_drawing.gd
godot --headless --path . --script res://scripts/verify_issue_42_pattern_grid_interaction.gd
godot --headless --path . --script res://scripts/verify_issue_43_tactile_tap_logic.gd
godot --headless --path . --script res://scripts/verify_issue_45_tactile_memory_flash.gd
godot --headless --path . --script res://scripts/verify_issue_46_playtest_level_jump.gd
godot --headless --path . --script res://scripts/verify_issue_47_tactile_text_trap.gd
godot --headless --path . --script res://scripts/verify_issue_48_debug_playtest_all.gd
godot --headless --path . --script res://scripts/verify_issue_51_scorecard_safe_area.gd
godot --headless --path . --script res://scripts/verify_issue_53_physics_draw_ios_path.gd
godot --headless --path . --script res://scripts/verify_issue_54_neutral_targets.gd
```

`verify_issue_4.gd` is the six-Level vertical-slice check. It verifies Levels 1-6, one Level per required template, completion through Level 6, Dur Token spend/recovery, Roast metrics, UQIQ Score changes, and save/load persistence.

`verify_issue_5_desktop_smoke.gd` is the scripted desktop smoke/stability check. It boots the main scene with a clean test save, completes Levels 1-6, checks Score Roastcards, replay, Dur Token recovery, save/load, and repeated replay cycles.

`verify_issue_7_pack_1_smoke.gd` is the Pack 1 smoke check. It boots the main scene with a clean test save, completes Levels 1-10 from the Level List through Score Roastcards, checks Level 10 replay/Best Attempt behavior, spends and recovers a Dur Token after Level 6, and verifies save/load plus app-restart persistence.

`verify_issue_8_pack_2_specs.gd` is the Pack 2 specs-only check for `content/levels/pack_02_words_are_lying.json`. It validates Pack 2 Level Specs against `docs/LEVEL_SPEC.md`; Pack 2 playability is covered by `verify_issue_10_pack_2_smoke.gd`.

`verify_issue_10_pack_2_smoke.gd` is the Pack 2 playable smoke check. It boots the expanded Level List, completes Levels 11-20 through Score Roastcards, and checks persistence plus Dur Token behavior.

`verify_issue_11_pack_3_specs.gd` is the Pack 3 specs-only check for `content/levels/pack_03_move_the_wrong_thing.json`. It validates the 10 `Move the Wrong Thing` Level Specs for Levels 21-30 against `docs/LEVEL_SPEC.md`, including supported templates, scoring thresholds, Roast buckets, solutions, and UQIQ Moments.

`verify_issue_11_pack_3_smoke.gd` is the Pack 3 playable smoke check. It boots the expanded Level List, confirms Pack 1/2/3 grouping, completes Levels 21-30 through Score Roastcards, and checks linear unlock, persistence, replay/Best Attempt behavior, UQIQ Score, Roasts, and Dur Token spend/recovery in the 30-Level progression.

`verify_issue_12_pack_4_specs.gd` is the Pack 4 specs-only check for `content/levels/pack_04_pattern_crimes.json`. It validates the 10 `Pattern Crimes` Level Specs for Levels 31-40 against `docs/LEVEL_SPEC.md`, including supported templates, scoring thresholds, Roast buckets, solutions, and UQIQ Moments.

`verify_issue_12_pack_4_smoke.gd` is the Pack 4 playable smoke check. It boots the expanded Level List, confirms Pack 1/2/3/4 grouping, completes Levels 31-40 through Score Roastcards, and checks linear unlock, persistence, replay/Best Attempt behavior, UQIQ Score, Roasts, and Dur Token spend/recovery in the 40-Level progression.

`verify_issue_13_pack_5_specs.gd` is the Pack 5 specs-only check for `content/levels/pack_05_brain_buffer_full.json`. It validates the 10 `Brain Buffer Full` Level Specs for Levels 41-50 against `docs/LEVEL_SPEC.md`, including supported templates, scoring thresholds, Roast buckets, solutions, and UQIQ Moments.

`verify_issue_13_pack_5_smoke.gd` is the Pack 5 playable smoke check. It boots the expanded Level List, confirms Pack 1/2/3/4/5 grouping, completes Levels 41-50 through Score Roastcards, and checks linear unlock, persistence, replay/Best Attempt behavior, UQIQ Score, Roasts, and Dur Token spend/recovery in the 50-Level progression.

`verify_issue_16_pack_6_specs.gd` is the Pack 6 specs-only check for `content/levels/pack_06_gravity_is_fake.json`. It validates the 10 `Gravity Is Fake` Level Specs for Levels 51-60 against `docs/LEVEL_SPEC.md`, including supported templates, scoring thresholds, Roast buckets, solutions, and UQIQ Moments.

`verify_issue_16_pack_6_smoke.gd` is the Pack 6 playable smoke check. It boots the expanded Level List, confirms Pack 1/2/3/4/5/6 grouping, completes Levels 51-60 through Score Roastcards, and checks Level 50 to Level 51 unlock, linear unlock through Level 60, persistence, replay/Best Attempt behavior, UQIQ Score, Roasts, and Dur Token spend/recovery in the 60-Level progression.

`verify_issue_19_scoring.gd` is the scoring polish check. It verifies one representative Level from each Pack against the UQIQ Score component formula, score clamps, DUR recovery scoring, capped replay Best Attempt behavior, and visible Speed/Actions/Roasts/DUR Score Roastcard rows.

`verify_issue_20_feedback.gd` is the minimal feedback polish check. It verifies tap, fail, success, Roast, Dur Token spend, and Dur Token recovery hooks in headless mode without changing action counts, scoring, unlock order, or persistence.

`verify_issue_21_judge_transitions.gd` is the Judge Face and transition polish check. It verifies list/play/score transition hooks, start/fail/Roast/success/score Judge Face reactions, replay, and Level List navigation.

`verify_issue_22_physics_draw.gd` is the Physics Draw polish check. It verifies selected-line state, release-result state, wrong release, correct release, action count, scoring, and persistence stay deterministic.

`verify_issue_23_ui_readability.gd` is the phone UI readability check. It verifies long labels and buttons use portrait-safe wrapping and ellipsis settings across the Level List, Play Screen, Physics Draw, and Score Roastcard surfaces.

`verify_issue_38_long_screen_fit.gd` is the long-screen fit check. It verifies content-heavy Play Screens and Score Roastcard expose lower actions/content inside portrait scroll containers.

`verify_issue_40_interaction_core.gd` is the interaction-core check. It verifies Drag Logic exposes a direct drag/drop playfield instead of `Move:` / `Drop on:` buttons, Physics Draw exposes a direct drawing surface instead of `Draw:` option buttons, and both interactions complete through Score Roastcard with persistence.

`verify_issue_41_pack_6_direct_drawing.gd` is the Pack 6 direct drawing check. It verifies every Pack 6 Physics Draw Level renders a direct drawing surface instead of `Draw:` fallback buttons, rejects a bad short line, and completes through its encoded drawing gesture.

`verify_issue_42_pattern_grid_interaction.gd` is the direct Pattern Grid check. It verifies Level 4 renders a markable grid instead of the old single-cell `Submit Pattern` flow, rejects a wrong row, and completes from marked grid state.

`verify_issue_43_tactile_tap_logic.gd` is the tactile Tap Logic check. It verifies Level 1 renders a direct tap scene instead of `CORRECT` / `WRONG` answer-choice buttons, rejects a wrong direct tap, accepts mouse/touch-shaped input, and completes through Score Roastcard.

`verify_issue_45_tactile_memory_flash.gd` is the tactile Memory Flash check. It verifies Level 5 renders direct memory tiles and recall slots instead of `Flash` / `Hide` / choice buttons, hides the flash order during recall, dedupes touch-emulated mouse presses, clears cleanly, rejects a wrong row, and completes through Score Roastcard.

`verify_issue_46_playtest_level_jump.gd` is the debug playtest access check. It verifies normal launch stays on the Level List while debug env `UQIQ_PLAYTEST_LEVEL=5` opens Level 5 directly without changing Local Profile unlock progression.

`verify_issue_47_tactile_text_trap.gd` is the tactile Text Trap check. It verifies Level 3 renders direct word tiles and an answer slot instead of a `LineEdit` / `Submit` flow, rejects a wrong tile, and completes through Score Roastcard from a direct tile tap.

`verify_issue_48_debug_playtest_all.gd` is the debug all-level phone playtest check. It verifies normal launch keeps later Levels locked, debug env `UQIQ_PLAYTEST_UNLOCK_ALL=1` makes supported Levels playable from the Level List without mutating Local Profile progression, and `UQIQ_PLAYTEST_LEVEL` still opens a target Level directly.

`verify_issue_51_scorecard_safe_area.gd` is the Score Roastcard safe-area and continuation check. It verifies notched-phone margin math, Level 01 completion to Next Level, later Pack 1 completion back to Level List, and score/profile persistence.

`verify_issue_53_physics_draw_ios_path.gd` is the Physics Draw iOS-path check. It verifies screen-touch drawing stays inside the draw surface, invalid flat lines fail, and a rising ramp classifies as `ramp_to_cup` before Release Ball completes Level 06.

`verify_issue_54_neutral_targets.gd` is the neutral target styling check. It verifies Level 04 grid cells and Levels 07/08/10 tap targets start with role-neutral colors while wrong/correct input feedback still works.

## Desktop Smoke

Manual smoke:

1. Reset the local save.
2. Run the project in desktop Godot.
3. Play Levels 1-6 end to end.
4. Replay one completed Level.
5. Spend a Dur Token on an unlocked incomplete Level, then complete that DUR'D Level and confirm the token returns.
6. Keep the app open for 10 minutes and confirm no crash.

Scripted stability equivalent:

```sh
godot --headless --path . --script res://scripts/verify_issue_5_desktop_smoke.gd | tee /tmp/uqiq-smoke.log
```

Save `/tmp/uqiq-smoke.log` as the smoke log. Passing means the scripted stability flow completed with no crash or error.

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
UQIQ_PLAYTEST_LEVEL=5 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_45_tactile_memory_flash.gd scripts/deploy_phone.sh
UQIQ_PLAYTEST_LEVEL=3 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_47_tactile_text_trap.gd scripts/deploy_phone.sh
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
