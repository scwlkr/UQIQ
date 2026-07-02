# PRD 0002: Content Factory

## Goal

Expand UQIQ from the six-Level vertical slice into curated offline Level Pack content.

## Scope

- Keep Level content in local JSON Pack Level Files.
- Keep v1.0 phone-first, portrait-only, Flat Vector Style.
- Build Level Packs as complete 10-Level units.
- Reuse the approved six Level Templates: Tap Logic, Drag Logic, Text Trap, Pattern Grid, Memory Flash, and Physics Draw.
- Preserve Local Profile progression, Best Attempts, UQIQ Score, Dur Tokens, DUR'D recovery, Roasts, Replay, and Score Roastcards.
- Add verification scripts for each completed Level Pack slice.

## Non-Goals

- Full 60-Level completion in one issue.
- Backend/accounts.
- Ads, IAP, Game Center, in-app AI, or user-created Levels.
- iPad-specific layout.
- Final App Store/TestFlight work.

## Decisions

- Content work advances one playable Level Pack slice at a time.
- A Pack Level File remains valid only when it contains exactly 10 complete Level Specs.
- Placeholder Level Specs are acceptable only before a Level Pack completion issue starts.
- Each playable Level needs a clear solution, scoring thresholds, all Roast buckets, and one UQIQ Moment.

## Acceptance Criteria

- The targeted Level Pack can be completed end to end from a clean Local Profile.
- Linear unlock, DUR'D spend/recovery, Replay, Score Roastcards, and UQIQ Score persistence still work across the targeted pack.
- The pack runs in desktop Godot with no crash during focused smoke verification.
- Follow-up issues track any out-of-scope polish, blocked device proof, or later pack work.

## Suggested Issues

1. Complete Pack 1 by replacing Levels 7-10 placeholders with playable Levels and full-pack verification.
2. Draft Pack 2 Level Specs.
3. Implement Pack 2 gameplay where existing templates need support changes.
4. Repeat one complete 10-Level Pack slice at a time until 60 curated Levels exist.
