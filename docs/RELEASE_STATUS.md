# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

Internal TestFlight setup passed for `com.wlkrlabs.uqiq`; install/launch proof now needs scwlkr to accept the TestFlight invite.

## Active Next Step

- GitHub issue: [#27 Internal TestFlight install and launch](https://github.com/scwlkr/UQIQ/issues/27)
- Branch: `codex/issue-25-distribution-archive-proof`

## Latest Proof

- Issue #25 uploaded UQIQ `0.1.0 (1)` to App Store Connect from the generated Xcode archive.
- Exported IPA proof: `/tmp/uqiq-ios-release-wlkrlabs/exported/UQIQ.ipa`, signed by `Apple Distribution: Shane Walker (QP9SJRTA44)`.
- Exported IPA Info.plist has non-empty camera, microphone, and photo-library usage descriptions.
- Issue #26 verified TestFlight processing: build `0.1.0 (1)` is `Ready to Test`, expires in 90 days, and is assigned to internal group `Internal Smoke`.
- Internal group `Internal Smoke` has automatic distribution, 1 build, and Shane Walker invited as internal tester.
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
- GitHub `next-step` label points to blocked issue #27.

## Known Blockers

- scwlkr must accept the internal TestFlight invite and install UQIQ `0.1.0 (1)` on a physical iPhone.

## Next Gate Needing scwlkr

Accept the TestFlight invite for UQIQ, install build `0.1.0 (1)`, and launch it once for proof.
