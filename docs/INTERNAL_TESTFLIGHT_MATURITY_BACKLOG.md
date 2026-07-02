# Internal TestFlight Maturity Backlog

Status: Internal-only. scwlkr is the only tester until UQIQ is more advanced.

## Current State

- Internal TestFlight build `0.1.0 (1)` is installed and launched on scwlkr's physical iPhone.
- Support/feedback email: `dev@wlkrlabs.com`.
- External testers are paused.
- No non-internal TestFlight build, TestFlight App Review, public link, App Review, or public release should start without explicit scwlkr approval.

## Maturity Gaps Before External Beta

1. Physical-device portrait proof
   - Done: CoreDevice set/read the physical iPhone orientation as `portrait`.
   - Done: portrait screenshot captured at `/tmp/uqiq-issue-36-portrait-proof.png` with size `1320 x 2868`.

2. Real playtest notes from scwlkr
   - Template added: `docs/INTERNAL_PLAYTEST_NOTES_TEMPLATE.md`.
   - Collect short notes from internal play only: confusing Levels, unfun Levels, unreadable UI, roasts that go too far, save/progress issues, and crashes.
   - Keep feedback private/local unless scwlkr asks to publish details.

3. Scorecard and long-screen fit
   - Draft App Store screenshot review showed useful Score Roastcard content, but lower content can be clipped in static full-screen captures.
   - Verify whether real play needs scrolling/fitting improvements before final screenshots.

4. Final screenshot polish
   - Current screenshots are draft local captures resized to 6.9-inch portrait dimensions.
   - Final assets should be captured/reviewed from intentional screens after the app feels ready.

5. Privacy/support URL publication
   - Draft page content exists, but `https://uqiq.wlkrlabs.com/privacy` and `/support` are not live.
   - Live hosting/DNS remains an approval gate.

6. Future external beta path
   - Current build is internal-TestFlight-only.
   - If external beta resumes, upload a non-internal replacement build and submit it for TestFlight App Review after scwlkr approval.

## Suggested Next Issues

1. Verify TestFlight portrait orientation and first-run presentation on physical iPhone.
2. Add a private internal playtest notes template for scwlkr.
3. Audit/fix Score Roastcard and long-screen fit for phone portrait.
4. Capture final device-native screenshot set after internal maturity pass.
5. Publish privacy/support page after scwlkr approves live hosting/DNS.
6. Resume external TestFlight only after scwlkr approves tester list and non-internal build.
