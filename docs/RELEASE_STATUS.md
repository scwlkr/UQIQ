# UQIQ Release Status

Last updated: 2026-07-01

## Current Phase

iOS physical-device proof passed; TestFlight/App Store distribution is blocked on Apple signing/auth.

## Active Next Step

- GitHub issue: [#25 Distribution archive and TestFlight upload proof](https://github.com/scwlkr/UQIQ/issues/25)
- Branch: `codex/issue-25-distribution-archive-proof`

## Latest Proof

- Issue #25 fixed the Release export preset to App Store method with `Apple Distribution`.
- Release export now generates `method=app-store` but Xcode archive fails because only Apple Development signing is installed.
- Upload auth is absent: `altool --list-providers` requires API key or Apple ID app-specific password/provider.
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
- GitHub `next-step` label points to blocked issue #25.

## Known Blockers

- Missing Apple Distribution signing identity/profile for `com.scwlkr.uqiq`.
- Missing App Store Connect upload authentication.

## Next Gate Needing scwlkr

scwlkr must provide or approve Apple Distribution signing/provisioning and App Store Connect upload credentials/app record access.
