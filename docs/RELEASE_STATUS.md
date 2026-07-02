# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

iOS physical-device proof and App Store Connect IPA export passed for `com.wlkrlabs.uqiq`; TestFlight upload is blocked on App Store Connect app-record setup.

## Active Next Step

- GitHub issue: [#25 Distribution archive and TestFlight upload proof](https://github.com/scwlkr/UQIQ/issues/25)
- Branch: `codex/issue-25-distribution-archive-proof`

## Latest Proof

- Issue #25 set the canonical bundle ID to `com.wlkrlabs.uqiq`.
- Direct Godot Release export still hits Xcode's manual identity conflict, but the generated Xcode project can archive and export via automatic cloud-managed distribution signing.
- Exported IPA proof: `/tmp/uqiq-ios-release-wlkrlabs/exported/UQIQ.ipa`, signed by `Apple Distribution: Shane Walker (QP9SJRTA44)`.
- Exported IPA Info.plist has non-empty camera, microphone, and photo-library usage descriptions.
- App Store Connect upload as internal-TestFlight-only failed because no app record exists for `com.wlkrlabs.uqiq`.
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
- GitHub `next-step` label points to blocked issue #25.

## Known Blockers

- Missing App Store Connect app record for `com.wlkrlabs.uqiq`.
- Browser App Store Connect login requires scwlkr password/2FA; passkey check found no passkeys.

## Next Gate Needing scwlkr

scwlkr must create or authorize creation of the App Store Connect app record for bundle ID `com.wlkrlabs.uqiq`.
