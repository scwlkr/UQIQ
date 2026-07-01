# UQIQ Roadmap

## Goal

Ship UQIQ v1.0 as a free, phone-only, portrait iOS game with 60 curated offline Levels, local progress, no backend, no accounts, no ads, no in-app purchases, and no in-app AI.

## Roadmap

1. **Planning Docs**
   - Maintain `CONTEXT.md` as the domain glossary.
   - Record hard-to-reverse decisions in `docs/adr/`.
   - Define the Level Spec format using one JSON Pack Level File per Level Pack.

2. **Godot Project Boot**
   - Create a Godot 4.x project.
   - Set portrait phone-only layout constraints.
   - Build the Flat Vector Style system, Judge Face, Play Screen, Level List, and Local Profile save path.

3. **Vertical Slice**
   - Build one playable Level for each Level Template: Tap Logic, Drag Logic, Text Trap, Pattern Grid, Memory Flash, and Physics Draw.
   - Include UQIQ Score placeholder, Dur Tokens, DUR'D state, Best Attempts, Roasts, and Replay.
   - Done when playable in desktop Godot and exported to one physical iPhone with save/load working, Dur Tokens working, UQIQ Score changing, Roasts showing, and no crash in a 10-minute play session.

4. **Content Factory**
   - Generate 100+ rough Level ideas.
   - Select and refine 60 into Level Specs.
   - Finalize Level Spec validation.
   - Create 60 Levels across 6 Level Packs; every Level needs at least one UQIQ Moment.
   - Verify each Level has solvable rules, scoring thresholds, at least three Roasts, Completion Mode, and Attempt Metrics.
   - Done when all 60 Levels can be completed by a fresh tester without developer help, every Level has at least three Roasts, every Level has scoring thresholds, there are no softlocks or impossible states, and a solution-known full run takes under 90 minutes.

5. **Polish Pass**
   - Tune UQIQ Score as a simple weighted average using completion, speed, action count, Roast usage, and DUR'D state, with visible range `UQIQ -20` through `UQIQ 420`.
   - Expand Context-Aware Roasts.
   - Add minimal punchy audio and haptics: tap blips, fail sting, success pop, Roast sting, Dur Token spend sound, and light success/fail haptics.
   - Add transitions, Judge Face reactions, and final flat vector visual polish.
   - Optional if cheap: native share sheet with text-only UQIQ Score / Level completion jokes. No custom image generation and no social SDKs.
   - Avoid music in v1.0 unless it is trivial and not annoying.

6. **iOS Export / TestFlight**
   - Export through Godot's iOS pipeline and Xcode.
   - Test on physical iPhones.
   - Run a tiny TestFlight beta with 3-10 people before App Store submission.
   - Ask beta testers to report only crashes, stuck/confusing Levels, unfun Levels, unreadable/tiny UI, and Roasts that go too far.
   - Use device logs/TestFlight crash reports first; evaluate free-tier Sentry or Firebase Crashlytics only after Godot iOS export is proven.
   - Fix crashes, save issues, layout issues, and review-blocking usability problems.

7. **App Store Prep**
   - Prepare app name `UQIQ`, subtitle `Puzzle Game for Giga Brains`, description, keywords, icon, screenshots, privacy details, age-rating questionnaire, support URL, and privacy policy.
   - App icon concept: Flat Vector Style Judge Face with UQIQ letter treatment on a vibrant background, readable at small iPhone sizes.
   - Host the minimal static policy/support page at `https://uqiq.wlkrlabs.com/privacy`.
   - Confirm no real IQ-test claims.
   - Submission blockers: crash on launch, save loss, impossible Level, softlock, unreadable phone UI, missing App Store metadata, missing Privacy Page, or any content that implies real IQ testing.

8. **Review / Release**
   - Submit to App Review.
   - Respond to review issues.
   - Release v1.0 manually after approval.
