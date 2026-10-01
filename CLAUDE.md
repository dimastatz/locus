# CLAUDE.md
This file provides guidance for AI coding assistants working on this Swift application.

## Project: Locus — *Lock Your Focus*

### Problem
Deep work on a laptop is hard when a full stack of distracting apps is one click away: email, Slack, social networks, browsers, and YouTube. Losing awareness for just 5 minutes can leave you wasting time or doing shallow work and entertainment instead of the task at hand.

### Solution
A native macOS app that locks the active application in full-screen mode. Until the focus timer runs out, leaving that app requires typing a long password — enough friction to break the impulse to switch away.

### Requirements
- **Menu bar app**: Locus runs in the background and shows an icon in the macOS menu bar (top toolbar). No Dock icon or main window.
- **Start a focus session**: Clicking the menu bar icon locks the currently active window, moves it to full-screen mode, and shows a countdown timer. Default duration is **25 minutes**.
- **Exit protection**: If the user tries to exit full-screen mode (or otherwise leave the locked app) before the timer ends, Locus shows a prompt requiring a long password to unlock.
- When the timer reaches zero, the lock is released automatically.

## Technical Guidance
- Language: Swift; target macOS only.
- Menu bar UI: `NSStatusItem` (AppKit) or `MenuBarExtra` (SwiftUI). Set `LSUIElement = YES` in Info.plist so the app has no Dock icon.
- Controlling other apps' windows (detecting the frontmost app, toggling full screen, observing exit attempts) requires the **Accessibility API** (`AXUIElement`) and the user granting Accessibility permission. Handle the not-yet-granted case gracefully and guide the user to System Settings.
- Use `NSWorkspace` notifications (e.g. `didActivateApplicationNotification`) to detect when the user switches away from the locked app, and bring it back to the front.
- Keep the app lightweight: minimal CPU usage while idle and during a session.
- Keep UI and locking logic separated so the session/timer logic can be unit tested.
