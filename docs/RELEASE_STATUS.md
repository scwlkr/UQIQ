# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

Release prep is paused. The current priority is making the gameplay core feel like interactive problem solving instead of answer-choice UI.

## Active Next Step

- GitHub issue: [#49 Direction needed from phone playtest build](https://github.com/scwlkr/UQIQ/issues/49)
- Branch: `codex/broad-interaction-polish`; scwlkr supplied broad direction to favor natural gestures, movement, and stronger app feel.

## Current Gameplay Proof

- Debug phone playtest supports direct level jump and is adding all-level Level List access.
- Level 2 Drag Logic has direct drag/drop.
- Level 4 Pattern Grid has direct row marking.
- Level 6 and Pack 6 Physics Draw have direct line drawing.
- Level 1 Tap Logic now has a direct tap scene instead of `CORRECT` / `WRONG` answer-choice buttons.
- Level 3 Text Trap now uses direct word tiles instead of `LineEdit` / `Submit`.
- Level 5 Memory Flash now has direct memory tiles and recall slots instead of choice buttons.
- Pattern Grid screens with a `cell_id`/`cell_ids` solution now render direct markable grids instead of `Submit Pattern` choice flow.
- Memory Flash screens with choices and a sequence now render direct recall slots and tile banks instead of `Flash` / `Hide` / `Submit` buttons.
- Direct Physics Draw resolves when the player lifts after drawing the line; the extra `Release Ball` tap is no longer part of the direct surface.
- Level List no longer exposes `res://content/...` source paths to players.

## Latest Verification

- Issue #43 closed with proof in commit `ada873e` and merge `42dcafd`.
- `verify_issue_43_tactile_tap_logic.gd` passed.
- Affected checks passed: `verify_issue_40_interaction_core.gd`, `verify_issue_42_pattern_grid_interaction.gd`, `verify_issue_4.gd`, `verify_issue_5_desktop_smoke.gd`, `verify_issue_7_pack_1_smoke.gd`.
- Full README verification floor passed through `verify_issue_43_tactile_tap_logic.gd`.
- `scripts/deploy_phone.sh` passed on physical iPhone `17 Hoe Max`: installed/launched UQIQ `0.1.1 (20260701224540)` and saved `/tmp/uqiq-ios-quick/uqiq-phone-20260701224540.png`.
- `verify_issue_45_tactile_memory_flash.gd` passed locally.
- Full README verification floor passed through `verify_issue_45_tactile_memory_flash.gd`.
- #45 phone deploy passed: installed/launched UQIQ `0.1.1 (20260701225006)` and saved `/tmp/uqiq-ios-quick/uqiq-phone-20260701225006.png`.
- `verify_issue_46_playtest_level_jump.gd` passed locally.
- Full README verification floor passed through `verify_issue_46_playtest_level_jump.gd`.
- #46 phone deploy passed with `UQIQ_PLAYTEST_LEVEL=5`: installed/launched UQIQ `0.1.1 (20260701225719)` and saved `/tmp/uqiq-ios-quick/uqiq-phone-20260701225719.png`.
- `verify_issue_47_tactile_text_trap.gd` passed locally.
- Full README verification floor passed through `verify_issue_47_tactile_text_trap.gd`.
- #47 phone deploy passed with `UQIQ_PLAYTEST_LEVEL=3`: installed/launched UQIQ `0.1.1 (20260701230643)` and saved `/tmp/uqiq-ios-quick/uqiq-phone-20260701230643.png`.
- `verify_issue_48_debug_playtest_all.gd` passed locally.
- Full README verification floor passed through `verify_issue_48_debug_playtest_all.gd`.
- #48 phone deploy passed with `UQIQ_PLAYTEST_UNLOCK_ALL=1`: installed/launched UQIQ `0.1.1 (20260701231050)` and saved `/tmp/uqiq-ios-quick/uqiq-phone-20260701231050.png`.
- Broad interaction polish pass verified locally with the full README floor:
  `verify_local_profile.gd`, `verify_issue_3.gd`, `verify_issue_4.gd`, `verify_issue_5_desktop_smoke.gd`, `verify_issue_7_pack_1_smoke.gd`, `verify_issue_8_pack_2_specs.gd`, `verify_issue_10_pack_2_smoke.gd`, `verify_issue_11_pack_3_specs.gd`, `verify_issue_11_pack_3_smoke.gd`, `verify_issue_12_pack_4_specs.gd`, `verify_issue_12_pack_4_smoke.gd`, `verify_issue_13_pack_5_specs.gd`, `verify_issue_13_pack_5_smoke.gd`, `verify_issue_16_pack_6_specs.gd`, `verify_issue_16_pack_6_smoke.gd`, `verify_issue_19_scoring.gd`, `verify_issue_20_feedback.gd`, `verify_issue_21_judge_transitions.gd`, `verify_issue_22_physics_draw.gd`, `verify_issue_23_ui_readability.gd`, `verify_issue_38_long_screen_fit.gd`, `verify_issue_40_interaction_core.gd`, `verify_issue_41_pack_6_direct_drawing.gd`, `verify_issue_42_pattern_grid_interaction.gd`, `verify_issue_43_tactile_tap_logic.gd`, `verify_issue_45_tactile_memory_flash.gd`, `verify_issue_46_playtest_level_jump.gd`, `verify_issue_47_tactile_text_trap.gd`, and `verify_issue_48_debug_playtest_all.gd`.
- Windowed Godot screenshot capture passed and refreshed `docs/app-store/screenshots/01_level_list.png` through `06_score_roastcard.png`.
- Second local polish loop compacted app chrome, added press/drag/release motion feedback, refreshed screenshots, and re-ran the full verification floor with Godot error-log scanning.
- Third local polish loop added live Drag Logic drop-zone hover feedback, snap-to-zone release motion, and verifier assertions for hover clearing; full verification floor passed again.
- Fourth local polish loop added Judge Face reaction pulse on visible state changes; focused transition/feedback checks and the full verification floor passed again.
- Fifth local polish loop rebuilt Score Roastcard into a score hero, two-column stat chips, and cleaner Roast/UQIQ Moment section; screenshots refreshed and full verification floor passed again.
- Sixth local polish loop replaced the Level List debug-style profile line with UQIQ/Dur/Unlocked metric chips; screenshots refreshed and full verification floor passed again.
- Seventh local polish loop added non-spoiling TAP/DRAG/DROP affordance tags to direct Tap Logic, Text Trap, Drag Logic tiles, and drop zones; screenshots refreshed and full verification floor passed again.
- Eighth local polish loop added SLOT/TAP/RESET affordance tags to Memory Flash, a draw runway cue to direct Physics Draw, refreshed screenshots, and re-ran the full verification floor with Godot error-log scanning.
- Physical phone deploy attempted after this pass, but `scripts/deploy_phone.sh` stopped before build/install with `No connected physical iPhone found`.

## Known Blockers

- Physical iPhone proof for this exact polish pass still needs the phone tunnel connected, then rerun:
  `UQIQ_PLAYTEST_UNLOCK_ALL=1 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_48_debug_playtest_all.gd scripts/deploy_phone.sh`.
- iOS simulator remains unsuitable for install proof with the current Godot 4.7 official simulator `libgodot.a` architecture mismatch.
- App Store submission, external TestFlight, live privacy/support hosting, and public release remain paused until gameplay core is stronger and scwlkr approves.

## Next Gate

Reconnect the physical iPhone tunnel, run the phone deploy proof for this polish pass, then use #49 to decide the next smallest gameplay-depth issue.
