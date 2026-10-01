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

Locus locks the app you're working in. One click puts its window in full screen and starts a timer. Until the timer runs out, leaving that app means typing a long password. That's enough friction to break the impulse to switch away.

## Features
- **Lives in the menu bar.** No Dock icon and no window to manage. The icon shows a countdown during a session.
- **One-click lock.** Click the icon and the app you're in goes full screen for a 25-minute session.
- **Exit protection.** ⌘Q, ⌘H, ⌘M, ⌘Tab, the full-screen shortcut and switching Spaces bring you back and ask for your unlock password.
- **A long password, typed.** At least 32 characters, no pasting. Locus stores only a salted hash in your Keychain.
- **Ends on its own.** When the timer runs out, the lock is released and you get a notification.

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
2. Click the lock icon in the menu bar. The first time, Locus asks you to set an unlock password.
3. The window goes full screen and a 25-minute countdown starts in the menu bar.
4. Trying to leave brings you back and asks for the unlock password. **Cancel** returns you to work.
5. When the timer ends, the lock is released and you get a notification.

| Action | How |
|---|---|
| Start a session | Left-click the menu bar icon |
| Open the menu | Right-click or ⌃-click the icon (any click during a session) |
| End a session early | Menu → **End Session Early…**, then type the password |
| Change the password | Menu → **Change Unlock Password…** (only between sessions) |

Locus is a commitment device, not parental control. Force-quitting it will release the lock.

## Development
```sh
swift build              # debug build
./scripts/test.sh        # unit tests (Swift Testing)
./scripts/coverage.sh    # tests + 95% line-coverage gate
./scripts/format.sh      # format with swift-format
./scripts/lint.sh        # swift-format lint + SwiftLint (brew install swiftlint)
./scripts/build-app.sh   # app bundle in build/
```

CI runs lint, tests with the coverage gate, and the app build on every pull request. Pushing a `v*` tag publishes a GitHub release with the zipped app.

| Path | Contents |
|---|---|
| `Sources/LocusCore/` | Session, timer, password and shortcut logic. No AppKit, unit tested. |
| `Sources/Locus/` | The menu bar app: status item, Accessibility window control, exit guard, prompts |
| `Tests/LocusCoreTests/` | Unit tests |
| `docs/specs/` | Product requirements ([PRD-0001](docs/specs/prd-0001-menu-bar-app.md) to [PRD-0004](docs/specs/prd-0004-session-completion.md)) |

## Roadmap
- Choose the session length from the menu
- Launch at login
- Breaks and repeating sessions (Pomodoro)
- Session history

## License
[MIT](LICENSE)
