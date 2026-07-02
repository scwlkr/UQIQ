# 60-Level Content QA

Issue: #18

Scope: Packs 1-6, Levels 1-60. Subagent C deep-audited Packs 5-6 and summarized the full local content set.

## Template Mix

| Pack | Levels | Primary | Mix |
| --- | --- | --- | --- |
| Orientation Is a Trap | 1-10 | Mixed tactile core | Tap Logic 3, Text Trap 2, Pattern Grid 1, Memory Flash 1, Physics Draw 3 |
| Words Are Lying | 11-20 | Text Trap | Text Trap 7, Tap Logic 1, Pattern Grid 1, Memory Flash 1 |
| Move the Wrong Thing | 21-30 | Drag Logic | Drag Logic 8, Pattern Grid 1, Memory Flash 1 |
| Pattern Crimes | 31-40 | Pattern Grid | Pattern Grid 8, Tap Logic 1, Memory Flash 1 |
| Brain Buffer Full | 41-50 | Memory Flash | Memory Flash 8, Tap Logic 1, Text Trap 1 |
| Gravity Is Fake | 51-60 | Physics Draw | Physics Draw 8, Tap Logic 1, Memory Flash 1 |

## Difficulty Curve

- 1-10: onboarding tricks plus one pass through all six approved templates.
- 11-20: text interpretation and exact accepted-input answers.
- 21-30: drag-object selection and target pairing.
- 31-40: pattern odd-one-out and grid discipline.
- 41-50: memory load increases from three-item flashes to repeated four-item flashes, with one Tap Logic break and one Text Trap break.
- 51-60: deterministic Physics Draw choices carry the finale, with one Tap Logic break and one late Memory Flash recall check.

## Audited Areas

- Required fields: Packs 5-6 keep all fields listed in `docs/LEVEL_SPEC.md`.
- Template support: Pack 5 uses exact Memory Flash sequences, Tap Logic target IDs, and Text Trap accepted input; Pack 6 uses deterministic Physics Draw `draw_id` choices plus supported Tap Logic and Memory Flash.
- Scoring: all Levels 41-60 have speed, action, and Roast thresholds. Late Pack 5 and Level 58 thresholds were tuned so the curve does not flatten at the end.
- Roasts: failure, delay, and Score Roastcard buckets exist for every Level 41-60. Tone stays clean, absurd, and aimed at in-game performance.
- UQIQ Moments: Levels 41-60 have concrete twists tied to shuffled order, reversed choice rows, fake physics, or template breaks.
- Draft markers: none found in owned pack files or this doc.

## Verification Floor

Run after all issue #18 slices merge:

```sh
godot --headless --path . --script res://scripts/verify_issue_13_pack_5_specs.gd
godot --headless --path . --script res://scripts/verify_issue_13_pack_5_smoke.gd
godot --headless --path . --script res://scripts/verify_issue_16_pack_6_specs.gd
godot --headless --path . --script res://scripts/verify_issue_16_pack_6_smoke.gd
```

Broader issue owner should also run the Pack 1-4 specs/smokes and desktop smoke before closing #18.

## Follow-Up Candidates

- Physics Draw currently plays as deterministic draw-choice plus release, matching the current slice. A richer draw sandbox belongs in polish.
- Memory Flash is manual Flash/Hide/Choose. Auto-hide after `flash_seconds` would make memory pressure stricter.
- Full 1-60 human playtest should check whether Pack 5 has too many similar short-sequence recalls despite the template breaks.
