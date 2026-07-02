# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

Internal TestFlight install/launch proof passed for `com.wlkrlabs.uqiq`; external beta is blocked on scwlkr inputs/approval.

## Active Next Step

- GitHub issue: [#34 External TestFlight beta approval and tester details](https://github.com/scwlkr/UQIQ/issues/34)
- Branch: `codex/issue-34-external-beta-blocker`

## Latest Proof

- Issue #25 uploaded UQIQ `0.1.0 (1)` to App Store Connect from the generated Xcode archive.
- Exported IPA proof: `/tmp/uqiq-ios-release-wlkrlabs/exported/UQIQ.ipa`, signed by `Apple Distribution: Shane Walker (QP9SJRTA44)`.
- Exported IPA Info.plist has non-empty camera, microphone, and photo-library usage descriptions.
- Issue #26 verified TestFlight processing: build `0.1.0 (1)` is `Ready to Test`, expires in 90 days, and is assigned to internal group `Internal Smoke`.
- Internal group `Internal Smoke` has automatic distribution, 1 build, and Shane Walker invited as internal tester.
- Issue #27 verified scwlkr accepted TestFlight, installed UQIQ `0.1.0 (1)`, and launched it on physical iPhone `17 Hoe Max`.
- Device proof: `xcrun devicectl device info apps --bundle-id com.wlkrlabs.uqiq` shows version `0.1.0`, build `1`.
- Launch screenshot: `/tmp/uqiq-testflight-installed-launch-proof.png`.
- Release-prep PRD added: `docs/prd/0004-app-store-testflight-release-prep.md`.
- App Store metadata/privacy draft added: `docs/APP_STORE_METADATA_DRAFT.md`.
- Privacy/support page draft added: `docs/PRIVACY_SUPPORT_PAGE_DRAFT.md`.
- Draft App Store screenshots added under `docs/app-store/screenshots/`; icon proof confirms `assets/icons/ios/app_store_1024x1024.png` is 1024x1024.
- Tiny TestFlight beta instructions added: `docs/TESTFLIGHT_BETA_DRAFT.md`.
- Release-candidate floor passed: README verification commands through `verify_issue_23_ui_readability.gd`, plus screenshot capture rerun.
- Current external-beta blocker: UQIQ `0.1.0 (1)` was uploaded as internal-TestFlight-only; external beta needs scwlkr approval for a non-internal replacement build and TestFlight App Review.
- Physical iPhone proof passed on `17 Hoe Max`: Xcode destination visible, signed Debug build succeeded, install succeeded, launch succeeded.
- `com.wlkrlabs.uqiq` device smoke hook passed in portrait with screenshot artifact: `/tmp/uqiq-issue-25-wlkrlabs-device-smoke-portrait-current.png`.
- Device smoke covered 60-spec load, isolated Local Profile, Level List, Play -> Score Roastcard, save/load, Dur spend/recovery, and no launch crash.
- Issue #23 UI readability slice closed with proof: `57f6acb`.
- Issue #22 Physics Draw polish slice closed with proof: `d9d08cc`.
- Issue #21 Judge Face/transition slice closed with proof: `359459d`.
- Issue #20 feedback slice closed with proof: `a3b9c3d`.
- Issue #19 scoring/Roastcard slice closed with proof: `90c2cec`.
- Polish Pass PRD added for next slices: `69f0cdf`.
- Latest full floor passed through `verify_issue_23_ui_readability.gd`.
- GitHub `next-step` label points to blocked issue #34.

## Known Blockers

- scwlkr must confirm the public support/feedback email.
- scwlkr must provide 3-10 external tester rows: `name,email,device_model,ios_version,notes`.
- scwlkr must approve uploading a non-internal TestFlight build and submitting it to TestFlight App Review.
- scwlkr must approve notifying testers after Apple approval.

## Next Gate Needing scwlkr

Provide the support email, tester list, and explicit approval for the non-internal TestFlight build/Beta App Review path.
