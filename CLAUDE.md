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
- [PRD-0005: Hold to Exit](docs/specs/prd-0005-hold-to-exit.md) (replaces the password unlock from PRD-0003)
- [PRD-0006: Brand Icon](docs/specs/prd-0006-brand-icon.md) (original-color logo in the menu bar; app icon on every pop-up)
- [PRD-0007: Confirm Before Locking](docs/specs/prd-0007-confirm-start.md) ("Are you sure you want to start a focus session?")
- [PRD-0008: Focus Duration Setting](docs/specs/prd-0008-focus-duration.md) (presets and custom 5–240 min, stored in `UserDefaults`)
- [PRD-0009: DMG Package](docs/specs/prd-0009-dmg-package.md) (`scripts/build-dmg.sh` → drag-to-install `Locus-<version>.dmg`)
- [PRD-0010: Completion Beep](docs/specs/prd-0010-completion-beep.md) ("beep beep" when the timer runs out)
- [PRD-0011: macOS Focus During Sessions](docs/specs/prd-0011-macos-focus-mode.md) (draft, not implemented: Do Not Disturb on at start, off at end, via Shortcuts)

## Technical Guidance
- Language: Swift; target macOS only.
- Menu bar UI: `NSStatusItem` (AppKit) or `MenuBarExtra` (SwiftUI). Set `LSUIElement = YES` in Info.plist so the app has no Dock icon.
- Controlling other apps' windows (detecting the frontmost app, toggling full screen, observing exit attempts) requires the **Accessibility API** (`AXUIElement`) and the user granting Accessibility permission. Handle the not-yet-granted case gracefully and guide the user to System Settings.
- Use `NSWorkspace` notifications (e.g. `didActivateApplicationNotification`) to detect when the user switches away from the locked app, and bring it back to the front.
- Keep the app lightweight: minimal CPU usage while idle and during a session.
- Keep UI and locking logic separated so the session/timer logic can be unit tested.

## Project Layout
Swift package, no Xcode project (builds with the Command Line Tools alone).
- `Sources/LocusCore/`: pure logic, no AppKit: `SessionController` (session lifecycle), `FocusSession`, `HoldToConfirm` (hold-to-exit progress, reset on interruption), `FocusDurationSetting` (session length, validation, persistence), `CompletionBeep` (beep pattern), `BlockedShortcuts`, `Countdown`.
- `Sources/Locus/`: the menu bar app: `AppDelegate` (status item, wiring), `LockedWindow` (Accessibility window control), `ExitGuard` (keyboard event tap + `NSWorkspace` observers), `PromptPanel` (shared non-activating dialog panel with the app icon), `StartPrompt` ("Are you sure you want to start a focus session?"), `DurationMenu` (Focus Duration submenu and custom-duration dialog), `ExitPrompt` ("Are you sure you want to exit?"), `HoldButton` (press-and-hold control, mouse only), `LegacyKeychain` (removes the old password item), `SessionNotifier` (notifications and completion beep), `MenuBarIcon` (fish logo in original colors; red alert badge during a session).
- `Tests/LocusCoreTests/`: Swift Testing unit tests for `LocusCore`.
- `Support/Info.plist`: app bundle plist (`LSUIElement`).
- `Support/MenuBar/`: menu bar icon in the logo's original colors (1×/2×), generated from `docs/images/locus-icon.png` by `swift scripts/make-menubar-icon.swift`.

## Commands
- Test: `./scripts/test.sh` (adds Swift Testing search paths when only the Command Line Tools are installed)
- Coverage gate: `./scripts/coverage.sh [min]`. Fails below 95% line coverage of `LocusCore`; the AppKit target isn't unit tested.
- Format: `./scripts/format.sh` (swift-format, config in `.swift-format`)
- Lint: `./scripts/lint.sh` (`swift format lint --strict` + `swiftlint --strict`, config in `.swiftlint.yml`; needs `brew install swiftlint`)
- Build: `swift build`
- Bundle: `./scripts/build-app.sh` → `build/Locus.app` (ad-hoc signed; set `CODESIGN_IDENTITY` to sign properly)
- DMG: `./scripts/build-dmg.sh [version]` → `build/Locus-<version>.dmg` (Locus.app + /Applications link; version defaults to `CFBundleShortVersionString`; `SKIP_APP_BUILD=1` reuses an existing `build/Locus.app`)

Before committing, run `./scripts/format.sh`, `./scripts/lint.sh` and `./scripts/coverage.sh`. CI runs the same scripts.

## CI/CD
- `.github/workflows/ci.yml`: on PRs and pushes to `main`, runs format & lint, tests with the 95% coverage gate, then builds `Locus.app` and the DMG and uploads both as artifacts.
- `.github/workflows/release.yml`: on a `v*` tag, runs the same checks and publishes a GitHub release with the DMG and the zipped app.

## v1 Decisions (resolving PRD open questions)
- Early exit (PRD-0005): hold Exit for 25 s (`HoldToConfirm.defaultDuration`); no escalation and no accessibility alternative yet. The legacy Keychain password item is deleted at launch.
- Click behavior: left-click asks "Are you sure you want to start a focus session?" (PRD-0007), then starts a 25-minute session; right-click / ⌃-click opens the menu.
- Apps without full-screen support: the session is refused with an explanation.
- Locked app quits or crashes: the session ends and the user is notified.
- Completion: "beep beep" (`Morse`, twice) plus a silent notification; the window stays in full screen.
