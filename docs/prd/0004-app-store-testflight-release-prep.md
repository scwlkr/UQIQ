# PRD 0004: App Store/TestFlight Release Prep

Status: parked until `docs/prd/0005-polished-six-level-core.md` proves the six-Level tactile core and scwlkr approves release prep.

## Goal

Move UQIQ from internal TestFlight proof to a submission-ready v1.0 package without starting external beta review, App Review, live hosting/DNS, or public release without explicit scwlkr approval.

## Scope

- Prepare a tiny TestFlight beta path for 3-10 testers, including tester list needs, invite copy, and feedback focus.
- Prepare App Store listing materials: app name, subtitle, description, keywords, categories, screenshots, icon, support URL, and privacy policy URL.
- Prepare App Store privacy and age-rating answers based on the shipped app behavior.
- Prepare the minimal privacy/support page content for `https://uqiq.wlkrlabs.com/privacy`.
- Define release-candidate proof required before any public review submission.
- Track owner-gated actions as blockers instead of treating them as done.

## Non-Goals

- Inviting external testers or starting Beta App Review.
- Submitting to App Review or releasing publicly.
- Making live DNS/hosting changes.
- Adding backend, accounts, ads, IAP, Game Center, in-app AI, tracking, analytics, or crash SDKs.
- New gameplay, content, or polish work unless a release gate proves it is required.

## Decisions

- UQIQ v1.0 remains free, offline, phone-only portrait, local-save only, and uses bundle ID `com.wlkrlabs.uqiq`.
- App Store copy must avoid real IQ-test claims; UQIQ is a joke puzzle score, not a diagnostic claim.
- Privacy answers should reflect the current app: no accounts, no backend, no ads, no IAP, no Game Center, no in-app AI, and no intentional data collection.
- Screenshots should show real gameplay surfaces from the TestFlight/release build, not mocked marketing art.
- External beta, App Store Connect submission, live hosting/DNS, and manual release are explicit approval/action gates.

## Acceptance Criteria

- App Store metadata draft exists and is ready for scwlkr review.
- Privacy and age-rating answer draft exists and matches app behavior.
- Privacy/support page content exists, with hosting/DNS blockers called out if not live.
- Screenshot and icon requirements are listed with proof assets or capture steps.
- Tiny beta instructions and tester-list requirements are documented without inviting testers automatically.
- Release-candidate verification checklist exists and includes internal TestFlight install/launch, full local verification floor, save/load, no launch crash, and no public-review blockers.
- GitHub issues track each remaining release-prep slice with exactly one `next-step`.

## Suggested Issues

1. Draft App Store listing metadata, privacy answers, and age-rating inputs.
2. Prepare privacy/support page content and hosting plan.
3. Capture App Store screenshot set and app icon proof from the release build.
4. Prepare tiny TestFlight beta instructions and tester invite checklist.
5. Run release-candidate verification and upload a replacement build if needed.
6. Enter App Store Connect metadata and prepare submission after scwlkr approval.

## First Next Step

Draft App Store listing metadata, privacy answers, and age-rating inputs without submitting anything to App Store Connect.
