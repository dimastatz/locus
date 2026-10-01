# CLAUDE.md
This file provides guidance for AI coding assistants working on this Swift application.

## Project: Locus — *Lock Your Focus*

### Problem
Deep work on a laptop is hard when a full stack of distracting apps is one click away: email, Slack, social networks, browsers, and YouTube. Losing awareness for just 5 minutes can leave you wasting time or doing shallow work and entertainment instead of the task at hand.

### Solution
A native macOS app that locks the active application in full-screen mode. Until the focus timer runs out, leaving that app requires confirming in a dialog by holding an Exit button for 25 seconds — enough friction to break the impulse to switch away.

### Requirements
- **Menu bar app**: Locus runs in the background and shows an icon in the macOS menu bar (top toolbar). No Dock icon or main window.
- **Start a focus session**: Clicking the menu bar icon locks the currently active window, moves it to full-screen mode, and shows a countdown timer. Default duration is **25 minutes**.
- **Exit protection**: If the user tries to exit full-screen mode (or otherwise leave the locked app) before the timer ends, Locus asks "Are you sure you want to exit?" with **Go Back** and **Exit** buttons. Exit must be pressed and held for 25 seconds to end the session.
- When the timer reaches zero, the lock is released automatically.

Detailed PRDs for each requirement live in `docs/specs/`:
- [PRD-0001: Menu Bar App](docs/specs/prd-0001-menu-bar-app.md)
- [PRD-0002: Start a Focus Session](docs/specs/prd-0002-focus-session.md)
- [PRD-0003: Exit Protection](docs/specs/prd-0003-exit-protection.md)
- [PRD-0004: Session Completion](docs/specs/prd-0004-session-completion.md)
- [PRD-0005: Hold to Exit](docs/specs/prd-0005-hold-to-exit.md) (replaces the password unlock from PRD-0003; not yet implemented)

## Technical Guidance
- Language: Swift; target macOS only.
- Menu bar UI: `NSStatusItem` (AppKit) or `MenuBarExtra` (SwiftUI). Set `LSUIElement = YES` in Info.plist so the app has no Dock icon.
- Controlling other apps' windows (detecting the frontmost app, toggling full screen, observing exit attempts) requires the **Accessibility API** (`AXUIElement`) and the user granting Accessibility permission. Handle the not-yet-granted case gracefully and guide the user to System Settings.
- Use `NSWorkspace` notifications (e.g. `didActivateApplicationNotification`) to detect when the user switches away from the locked app, and bring it back to the front.
- Keep the app lightweight: minimal CPU usage while idle and during a session.
- Keep UI and locking logic separated so the session/timer logic can be unit tested.

## Project Layout
Swift package, no Xcode project (builds with the Command Line Tools alone).
- `Sources/LocusCore/`: pure logic, no AppKit: `SessionController` (session lifecycle), `FocusSession`, `PasswordVault` (salted SHA-256 hash behind a `SecretStore`), `BlockedShortcuts`, `Countdown`.
- `Sources/Locus/`: the menu bar app: `AppDelegate` (status item, wiring), `LockedWindow` (Accessibility window control), `ExitGuard` (keyboard event tap + `NSWorkspace` observers), `PasswordPrompt` (non-activating panel shown over full screen), `KeychainSecretStore`, `SessionNotifier`.
- `Tests/LocusCoreTests/`: Swift Testing unit tests for `LocusCore`.
- `Support/Info.plist`: app bundle plist (`LSUIElement`).

## Commands
- Test: `./scripts/test.sh` (adds Swift Testing search paths when only the Command Line Tools are installed)
- Coverage gate: `./scripts/coverage.sh [min]`. Fails below 95% line coverage of `LocusCore`; the AppKit target isn't unit tested.
- Format: `./scripts/format.sh` (swift-format, config in `.swift-format`)
- Lint: `./scripts/lint.sh` (`swift format lint --strict` + `swiftlint --strict`, config in `.swiftlint.yml`; needs `brew install swiftlint`)
- Build: `swift build`
- Bundle: `./scripts/build-app.sh` → `build/Locus.app` (ad-hoc signed; set `CODESIGN_IDENTITY` to sign properly)

Before committing, run `./scripts/format.sh`, `./scripts/lint.sh` and `./scripts/coverage.sh`. CI runs the same scripts.

## CI/CD
- `.github/workflows/ci.yml`: on PRs and pushes to `main`, runs format & lint, tests with the 95% coverage gate, then builds `Locus.app` and uploads it as an artifact.
- `.github/workflows/release.yml`: on a `v*` tag, runs the same checks and publishes a GitHub release with the zipped app.

## v1 Decisions (resolving PRD open questions)
- Password: set once by the user (at least 32 characters, typed, no paste); prompted before the first session; can be changed from the menu while idle. **To be replaced by PRD-0005 (hold to exit).**
- Click behavior: left-click starts a 25-minute session immediately; right-click / ⌃-click opens the menu.
- Apps without full-screen support: the session is refused with an explanation.
- Locked app quits or crashes: the session ends and the user is notified.
- Completion: notification with default sound; the window stays in full screen.
