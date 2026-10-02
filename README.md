<div align="center">
<h1 align="center"> Locus </h1> 
<h3>Locus is a native macOS app designed to help you lock your focus. Create focused work sessions, reduce distractions, and keep your attention on what matters. Simple, lightweight, and built for deep work — right where you work.
</br></h3>
<img src="https://img.shields.io/badge/Progress-50%25-yellow"> <img src="https://github.com/dimastatz/locus/actions/workflows/ci.yml/badge.svg"> <img src="https://img.shields.io/badge/macOS-13%2B-blue"> <img src="https://img.shields.io/badge/Feedback-Welcome-green">
</br>
</br>
<img src="./docs/images/locus-icon.png" width="256px"> 
</div>

## Why Locus
Deep work on a laptop is hard when email, Slack, social networks, browsers and YouTube are one click away. Lose awareness for five minutes and you're doing shallow work or scrolling.

Locus locks the app you're working in. One click puts its window in full screen and starts a timer. Until the timer runs out, leaving that app means holding an Exit button for 25 seconds. That's long enough to notice what you're doing and change your mind.

## Features
- **Lives in the menu bar.** No Dock icon and no window to manage. The Locus fish sits in the menu bar in its original colors; during a session it gets a red alert badge and a countdown.
- **One-click lock.** Click the icon and the app you're in goes full screen for a focus session: 25 minutes by default, or whatever you choose.
- **Exit protection.** ⌘Q, ⌘H, ⌘M, ⌘Tab, the full-screen shortcut and switching Spaces bring you back and ask "Are you sure you want to exit?"
- **Hold to exit.** Ending early means holding **Exit** for 25 seconds. Let go or drag off and it starts over. **Go Back** (or Return/Esc) returns you to work.
- **Ends on its own.** When the timer runs out, the lock is released, Locus beeps twice and you get a notification.
- **Quiet while you work.** Optionally turns on Do Not Disturb for the session and off again when it ends.

## Install
Locus is built from source for now. You need macOS 13 or later and the Swift toolchain (Xcode or the Command Line Tools).

```sh
git clone https://github.com/dimastatz/locus.git
cd locus
./scripts/build-app.sh   # builds build/Locus.app
open build/Locus.app
```

On first launch, grant Locus Accessibility access in **System Settings → Privacy & Security → Accessibility**. Locus needs it to put windows in full screen and keep them there.

> **Note:** The build is ad-hoc signed, so macOS asks for Accessibility access again after every rebuild. To avoid this, sign with your own identity: `CODESIGN_IDENTITY="Apple Development: …" ./scripts/build-app.sh`.

## Usage
1. Click into the app you want to focus on.
2. Click the Locus fish in the menu bar and confirm with **Start**. The window goes full screen and the countdown (25 minutes by default) starts in the menu bar.
3. Trying to leave brings you back and asks "Are you sure you want to exit?" **Go Back** returns you to work; holding **Exit** for 25 seconds ends the session.
4. When the timer ends, the lock is released, Locus beeps twice and you get a notification.

| Action | How |
|---|---|
| Start a session | Left-click the menu bar icon, then **Start** (or Return) |
| Open the menu | Right-click or ⌃-click the icon (any click during a session) |
| Turn on Do Not Disturb during sessions | Menu → **Turn On Do Not Disturb During Sessions** (one-time setup in Shortcuts) |
| Change the session length | Menu → **Focus Duration** → 15 / 25 / 45 / 60 / 90 min or **Custom…** (5–240 min) |
| End a session early | Menu → **End Session Early…**, then hold **Exit** for 25 seconds |

Locus is a commitment device, not parental control. Force-quitting it will release the lock.

## Development
```sh
swift build              # debug build
./scripts/test.sh        # unit tests (Swift Testing)
./scripts/coverage.sh    # tests + 95% line-coverage gate
./scripts/format.sh      # format with swift-format
./scripts/lint.sh        # swift-format lint + SwiftLint (brew install swiftlint)
./scripts/build-app.sh   # app bundle in build/
./scripts/build-dmg.sh   # drag-to-install disk image: build/Locus-<version>.dmg
```

CI runs lint, tests with the coverage gate, and the app build on every pull request. Pushing a `v*` tag publishes a GitHub release with the DMG and the zipped app.

| Path | Contents |
|---|---|
| `Sources/LocusCore/` | Session, timer, hold-to-exit and shortcut logic. No AppKit, unit tested. |
| `Sources/Locus/` | The menu bar app: status item, Accessibility window control, exit guard, prompts |
| `Tests/LocusCoreTests/` | Unit tests |
| `docs/specs/` | Product requirements ([PRD-0001](docs/specs/prd-0001-menu-bar-app.md) to [PRD-0004](docs/specs/prd-0004-session-completion.md)) |

## Roadmap
- Launch at login
- Breaks and repeating sessions (Pomodoro)
- Session history

## License
[MIT](LICENSE)
