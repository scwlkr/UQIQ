# UQIQ Release Status

Last updated: 2026-07-01

## Current Phase

iOS Export / TestFlight blocked on physical-device proof.

## Active Next Step

- GitHub issue: [#24 Physical iPhone and provisioning for release proof](https://github.com/scwlkr/UQIQ/issues/24)
- Branch: `codex/issue-24-physical-iphone-release-proof`

## Latest Proof

- Issue #23 UI readability slice closed with proof: `57f6acb`.
- Issue #22 Physics Draw polish slice closed with proof: `d9d08cc`.
- Issue #21 Judge Face/transition slice closed with proof: `359459d`.
- Issue #20 feedback slice closed with proof: `a3b9c3d`.
- Issue #19 scoring/Roastcard slice closed with proof: `90c2cec`.
- Polish Pass PRD added for next slices: `69f0cdf`.
- Latest full floor passed through `verify_issue_23_ui_readability.gd`.
- GitHub `next-step` label now points only to blocked issue #24.

## Known Blockers

- Physical iPhone proof is blocked until scwlkr says the iPhone is connected, trusted, unlocked, and visible to Xcode.
- Apple signing/provisioning must be available for the UQIQ bundle before TestFlight/App Store proof.

## Next Gate Needing scwlkr

Connect/trust/unlock the physical iPhone, enable Developer Mode if required, and confirm Xcode can use it as a run destination.
