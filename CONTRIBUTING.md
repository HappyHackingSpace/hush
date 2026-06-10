# Contributing to Hush

Thanks for helping build Hush. It is a free, open-source project from Happy Hacking Space.

## Requirements

- macOS 14 or later
- Xcode 26 (the macOS 26 SDK is needed for the on-device AI features)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) and [SwiftLint](https://github.com/realm/SwiftLint): `brew install xcodegen swiftlint`

## Build and test

```sh
swift test            # run the HushCore tests
swiftlint --strict    # lint
xcodegen generate     # generate Hush.xcodeproj from project.yml
open Hush.xcodeproj    # build and run the app
```

`Hush.xcodeproj` is generated from `project.yml` and is not committed. Run `xcodegen generate`
after pulling changes or editing `project.yml`.

## Project layout

- `Sources/HushCore`: pure, tested logic (scripts, tokenizing, alignment, cues, pacing,
  Markdown parsing). No AppKit; this is where unit tests live.
- `Sources/Hush`: the macOS app (notch overlay, speech, hand gestures, recording, UI).
- `project.yml`: the XcodeGen project definition.
- `scripts/`: the release build and asset generators.

## Code style

- Keep logic that can be tested in `HushCore` and cover it with tests.
- SwiftLint must pass with `--strict`.
- Match the surrounding style. Comments explain why, not what.

## Pull requests

- `main` is protected and requires a pull request.
- Make sure `swift test`, `swiftlint --strict`, and the app build all pass before opening a PR.
- Keep changes focused and commits small.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org). The release version is bumped
from them:

- `feat: ...` bumps the minor version.
- `fix: ...` (and others like `docs:`, `chore:`) bump the patch version.
- A `!` after the type or a `BREAKING CHANGE:` footer bumps the major version.

## Release

Releases are automatic. Every merge to `main` runs
[`.github/workflows/release.yml`](.github/workflows/release.yml), which computes the next
[semantic version](https://semver.org) from the commits, builds an unsigned `Hush.dmg` with
`scripts/release.sh`, and publishes a GitHub Release with categorized notes.
