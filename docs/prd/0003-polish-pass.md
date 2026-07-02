# PRD 0003: Polish Pass

Status: parked until `docs/prd/0005-polished-six-level-core.md` proves the six-Level tactile core and scwlkr approves a v1.0 scope.

## Goal

Turn the complete 60-Level offline build into a first-pass polished iOS release candidate.

## Scope

- Keep all 60 curated offline Levels, Local Profile, Linear Unlock, Best Attempts, Dur Tokens, DUR'D recovery, Roasts, Replay, and Score Roastcards.
- Tune UQIQ Score and Score Roastcards so completion, speed, action count, Roast usage, and DUR context feel legible.
- Add minimal punchy audio and haptics for tap, fail, success, Roast, Dur Token spend, and Dur Token recovery.
- Add Judge Face reactions, transitions, and small Flat Vector Style polish where it improves repeated play.
- Improve Physics Draw feel only where cheap and deterministic enough for v1.0.
- Preserve phone-only portrait readability and the existing README verification floor.

## Non-Goals

- New Level Packs or replacement Level content.
- Backend, accounts, ads, IAP, Game Center, in-app AI, or social SDKs.
- iPad-specific layout.
- TestFlight, App Store metadata submission, or App Review release.
- Full music pass unless it is trivial and not annoying.

## Decisions

- Polish work advances in small GitHub issue slices.
- Prefer built-in Godot audio, haptics, animation, and UI primitives before adding dependencies.
- Keep deterministic gameplay behavior for v1.0; polish should not make Level solutions random or harder to verify.
- Every gameplay-facing polish slice must keep the full README verification floor passing before closure.

## Acceptance Criteria

- UQIQ Score and Score Roastcards are no longer placeholder loops.
- Core taps, fails, completions, Roasts, and Dur Token moments have minimal feedback.
- Judge Face and transition polish make Level List -> Play -> Score Roastcard feel intentional.
- No polish slice regresses Local Profile persistence, unlock order, Dur Token cap behavior, or Pack 1-6 smoke checks.
- Human playtest and iOS release proof are tracked separately once local polish is ready.

## Suggested Issues

1. Tune UQIQ Score and Score Roastcards.
2. Add minimal audio and haptics.
3. Add Judge Face reactions and transitions.
4. Polish Physics Draw readability and feel if it stays cheap.
5. Run phone UI polish/readability sweep.
6. Run human playtest triage before TestFlight.

## First Next Step

Add minimal audio and haptics without changing Level rules or persistence.
