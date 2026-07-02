# UQIQ Release Status

Last updated: 2026-07-01

## Current Phase

iOS physical-device proof passed; TestFlight/App Store distribution proof is next.

## Active Next Step

- GitHub issue: [#24 Physical iPhone and provisioning for release proof](https://github.com/scwlkr/UQIQ/issues/24)
- Branch: `codex/issue-24-physical-iphone-release-proof`

## Latest Proof

- Issue #24 physical iPhone proof passed on `17 Hoe Max`: Xcode destination visible, signed Debug build succeeded, install succeeded, launch succeeded.
- Device smoke hook passed in portrait with screenshot artifact: `/tmp/uqiq-issue-24-device-smoke-portrait.png`.
- Device smoke covered 60-spec load, isolated Local Profile, Level List, Play -> Score Roastcard, save/load, Dur spend/recovery, and no launch crash.
- Issue #23 UI readability slice closed with proof: `57f6acb`.
- Issue #22 Physics Draw polish slice closed with proof: `d9d08cc`.
- Issue #21 Judge Face/transition slice closed with proof: `359459d`.
- Issue #20 feedback slice closed with proof: `a3b9c3d`.
- Issue #19 scoring/Roastcard slice closed with proof: `90c2cec`.
- Polish Pass PRD added for next slices: `69f0cdf`.
- Latest full floor passed through `verify_issue_23_ui_readability.gd`.
- GitHub `next-step` label currently points to issue #24 until the distribution issue is opened.

## Known Blockers

- Godot generic archive still fails on provisioning unless Xcode build settings are supplied manually.
- TestFlight/App Store distribution archive/upload has not been proved yet.

## Next Gate Needing scwlkr

scwlkr may need to approve or complete Apple Developer/App Store Connect actions for distribution signing, app record, TestFlight upload, or App Store submission.
