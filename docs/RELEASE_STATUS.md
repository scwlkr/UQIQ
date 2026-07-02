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
- Ninth local polish loop hid desktop-style scrollbars while preserving scroll containers for long play screens and Level List; screenshots refreshed and long-screen fit passed again.
- Tenth local polish loop restyled direct Tap Logic targets as framed evidence tiles instead of bright answer-button blocks; Level 1 screenshot refreshed and full verification floor passed again.
- Eleventh local polish loop compacted Score Roastcard completion/best/unlock status into one clean row; Score Roastcard screenshot refreshed and full verification floor passed again.
- Twelfth local polish loop added Drag Logic to the draft screenshot set and tightened drag/drop columns so drop zones stay inside the playfield; screenshots refreshed and full verification floor passed again.
- Thirteenth local polish loop added Text Trap to the draft screenshot set; visual check confirmed the direct answer-slot/tile layout is clean, screenshots refreshed, and full verification floor passed again.
- Fourteenth local polish loop moved Drag Logic and Text Trap captures before Score Roastcard completion so all play screenshots show the same clean starting UQIQ/Dur header; screenshots refreshed and visually checked.
- Fifteenth local polish loop restyled direct Pattern Grid cells as framed TAP evidence tiles instead of bright answer-button blocks; Pattern Grid screenshot refreshed and full verification floor passed again.
- Sixteenth local polish loop restyled Text Trap and Memory Flash tiles as framed evidence tiles instead of bright answer-button blocks; screenshots refreshed and full verification floor passed again.
- Seventeenth local polish loop restyled Drag Logic draggable tiles as framed evidence tiles while preserving direct drag/drop behavior; Drag Logic screenshot refreshed and full verification floor passed again.
- Eighteenth local polish loop replaced the Level List debug loader status with player-facing progress copy; Level List screenshot refreshed and full verification floor passed again.
- Nineteenth local polish loop demoted the play-screen Roast action into a compact framed secondary control so gesture surfaces stay visually primary; play screenshots refreshed and full verification floor passed again.
- Twentieth local polish loop replaced debug-like Physics Draw state labels with shorter player-facing line/test copy; Physics Draw screenshot refreshed and full verification floor passed again.
- Twenty-first local polish loop restyled playable Level List and active DUR controls as framed buttons to match the direct-play surfaces; Level List screenshot refreshed and full verification floor passed again.
- Twenty-second local polish loop shortened playable Level List row labels so the active level title fits without low-value status truncation; Level List screenshot refreshed and full verification floor passed again.
- Twenty-third local polish loop removed redundant locked-state suffixes from disabled Level List rows so titles fit more naturally; Level List screenshot refreshed and full verification floor passed again.
- Twenty-fourth local polish loop removed inactive DUR buttons from locked Level List rows while preserving row alignment; Level List screenshot refreshed and full verification floor passed again.
- Twenty-fifth local polish loop shifted shared play surfaces from tan paper to a cooler app-integrated palette; screenshots refreshed and full verification floor passed again.
- Twenty-sixth local polish loop made screen transitions fade in more visibly while skipping animation during screenshot capture; screenshot capture stayed stable and full verification floor passed again.
- Twenty-seventh local polish loop framed Drag Logic drop zones to match draggable tiles and sharpen hover target feedback; Drag Logic screenshot refreshed and full verification floor passed again.
- Twenty-eighth local polish loop wrapped direct Pattern Grid cells in the shared playfield surface so every direct interaction mode uses the same target stage language; Pattern Grid screenshot refreshed and full verification floor passed again.
- Twenty-ninth local polish loop framed Text Trap answer slots and Memory Flash recall slots so target areas match the tactile tile language; Text Trap and Memory Flash screenshots refreshed and full verification floor passed again.
- Thirtieth local polish loop framed Score Roastcard Replay and Level List controls so completion navigation matches the rest of the app's tactile control language; Score Roastcard screenshot refreshed and full verification floor passed again.
- Thirty-first local polish loop framed the play-screen back control so navigation chrome matches the app's tactile button language; play screenshots refreshed and full verification floor passed again.
- Thirty-second local polish loop changed direct tap/text/memory selected states from flat yellow fills to framed yellow contact feedback; screenshot capture stayed stable and full verification floor passed again.
- Thirty-third local polish loop changed marked Pattern Grid cells to the same framed yellow contact feedback used by other direct selections; screenshot capture stayed stable and full verification floor passed again.
- Thirty-fourth local polish loop framed the play header UQIQ and Dur counters as compact status chips so score state matches the app's tactile chrome; play screenshots refreshed and full verification floor passed again.
- Thirty-fifth local polish loop made Drag Logic drop zones read as recessed slots instead of movable tiles and removed the ASCII arrow hint; Drag Logic screenshot refreshed and full verification floor passed again.
- Thirty-sixth local polish loop strengthened Physics Draw guide-line and lift/draw cue contrast so the drawing gesture reads naturally on the playfield; Physics Draw screenshot refreshed and full verification floor passed again.
- Thirty-seventh local polish loop compacted Score Roastcard spacing so Replay and Level List controls are fully visible in the first portrait viewport; Score Roastcard screenshot refreshed and full verification floor passed again.
- Thirty-eighth local polish loop made Memory Flash recall slots read as recessed targets distinct from tappable tiles; Memory Flash screenshot refreshed and full verification floor passed again.
- Thirty-ninth local polish loop made Text Trap's answer slot read as a recessed target distinct from tappable word tiles; Text Trap screenshot refreshed and full verification floor passed again.
- Fortieth local polish loop split Level List pack headings from level ranges so long pack names no longer wrap with a dangling separator; Level List screenshot refreshed and full verification floor passed again.
- Forty-first local polish loop made Drag Logic wrong drops return the tile to its origin and added active drag contact feedback while a tile is moving; screenshot capture stayed stable and full verification floor passed again.
- Forty-second local polish loop added deterministic verifier coverage for Drag Logic failed-drop return behavior so the bounce-back movement stays protected; screenshot capture stayed stable and full verification floor passed again.
- Forty-third local polish loop added subtle slot pulse feedback when Text Trap and Memory Flash choices land in their target slots; screenshot capture stayed stable and full verification floor passed again.
- Forty-fourth local polish loop removed raw template-name headers from play stages and rewrote the leftover Tap Logic startup helper so Level screens read less like a test harness; screenshots refreshed and full verification floor passed again.
- Forty-fifth local polish loop rewrote Physics Draw state copy from debug-style `Line/Test` labels into player-facing `Path` and `Lift/Release` prompts; Physics Draw screenshot refreshed and full verification floor passed again.
- Forty-sixth local polish loop rewrote Score Roastcard summary copy to remove shorthand like `Best 1A/0R`, `Total Delta`, and `Attempt raw`; Score Roastcard screenshot refreshed and full verification floor passed again.
- Forty-seventh local polish loop shortened direct play-screen helper lines for Drag Logic, Text Trap, Pattern Grid, Memory Flash, and Physics Draw so the screens feel less like QA instructions; screenshots refreshed and full verification floor passed again.
- Forty-eighth local polish loop widened the play header score chip so `UQIQ 100` no longer clips to `UQIQ 1`, and added readability verifier coverage for the full score label; screenshots refreshed and full verification floor passed again.
- Forty-ninth local polish loop changed the play header Dur chip to show full token capacity (`Dur 3/3`) and added readability verifier coverage for both header metric chips; screenshots refreshed and full verification floor passed again.
- Fiftieth local polish loop removed repeated `TAP` scaffolding from direct Pattern Grid cells so the board reads as the puzzle values first; Pattern Grid screenshot refreshed and full verification floor passed again.
- Physical phone deploy attempted after this pass, but `scripts/deploy_phone.sh` stopped before build/install with `No connected physical iPhone found`.

## Known Blockers

- Physical iPhone proof for this exact polish pass still needs the phone tunnel connected, then rerun:
  `UQIQ_PLAYTEST_UNLOCK_ALL=1 UQIQ_VERIFY_SCRIPT=res://scripts/verify_issue_48_debug_playtest_all.gd scripts/deploy_phone.sh`.
- iOS simulator remains unsuitable for install proof with the current Godot 4.7 official simulator `libgodot.a` architecture mismatch.
- App Store submission, external TestFlight, live privacy/support hosting, and public release remain paused until gameplay core is stronger and scwlkr approves.

## Next Gate

Reconnect the physical iPhone tunnel, run the phone deploy proof for this polish pass, then use #49 to decide the next smallest gameplay-depth issue.
