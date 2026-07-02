# PRD 0001: Vertical Slice

Status: historical baseline. Current work is superseded by `docs/prd/0005-polished-six-level-core.md`.

## Goal

Build the first playable proof of UQIQ's full loop before producing all 60 Levels.

## Scope

- Godot 4.x project boot.
- Portrait phone-only layout.
- Flat Vector Style foundation.
- Judge Face placeholder.
- One fake Pack Level File.
- Level List -> Play Screen -> Score Roastcard flow.
- Local Profile save/load.
- UQIQ Score placeholder that changes from Attempt Metrics.
- Dur Tokens, DUR'D state, Replay, Roasts.
- One playable Level for each Level Template: Tap Logic, Drag Logic, Text Trap, Pattern Grid, Memory Flash, Physics Draw.

## Non-Goals

- Full 60-Level content pack.
- App Store submission.
- Backend/accounts.
- Ads, IAP, Game Center, or in-app AI.
- iPad-specific layout.

## Acceptance Criteria

- Runs in desktop Godot.
- Exports to one physical iPhone.
- Six Levels are playable end to end.
- Save/load works after app restart.
- Dur Tokens can be spent and recovered by completing DUR'D Levels.
- UQIQ Score changes after Level completion.
- Roasts and Score Roastcards appear.
- No crash in a 10-minute play session.

## Suggested Issues

1. Boot Godot project skeleton and placeholder content loader.
2. Build Level List, Play Screen, and Score Roastcard routing.
3. Add Local Profile, Best Attempts, UQIQ Score placeholder, Dur Tokens, and DUR'D state.
4. Build six Vertical Slice Levels, one per Level Template.
5. Export to iPhone and fix smoke-test issues.

## First Next Step

Boot the Godot project skeleton and prove one Tap Logic Level can load from a fake Pack Level File.
