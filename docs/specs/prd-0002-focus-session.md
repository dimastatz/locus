# PRD-0002: Start a Focus Session

| Field   | Value                     |
|---------|---------------------------|
| Status  | Draft                     |
| Created | 2026-10-01                |
| Related | [PRD-0001](prd-0001-menu-bar-app.md), [PRD-0003](prd-0003-exit-protection.md), [PRD-0004](prd-0004-session-completion.md) |

## Overview
Clicking the Locus menu bar icon locks the currently active window, moves it into full-screen mode, and shows a countdown timer. The default duration is 25 minutes.

## Problem
Deep work fails when other apps are one click away. Losing awareness for just 5 minutes is enough to drift into email, Slack, social networks or YouTube. Starting a session must be a single action that immediately removes those options.

## Goals
- One click turns the app you are working in into the only app you can use.
- The user always knows how much focus time is left.

## Non-Goals
- Locking multiple apps/windows at once.
- Blocking websites inside a browser.
- Task tracking, statistics, or history (future PRDs).

## User Stories
- As a user working in an app, I click the Locus icon, confirm ([PRD-0007](prd-0007-confirm-start.md)), and that window goes full screen and is locked.
- As a user in a session, I can glance at the remaining time.

## Functional Requirements
1. **Target selection** — the target is the focused window of the frontmost application at the moment the icon is clicked (excluding Locus itself), resolved via `NSWorkspace.frontmostApplication` and the Accessibility API (`AXUIElement`, `kAXFocusedWindowAttribute`).
2. **Full screen** — the target window is moved into native macOS full-screen mode (`AXFullScreen` attribute). If already full screen, it stays as is.
3. **Lock** — the session records the target app (bundle ID + PID) and window. Exit attempts are handled by [PRD-0003](prd-0003-exit-protection.md).
4. **Timer**
   - Default duration: **25 minutes**.
   - Countdown starts as soon as the window is full screen.
   - Remaining time is shown in the menu bar (`mm:ss`), and optionally as a small unobtrusive overlay.
   - Timer is based on wall-clock end time, so it stays correct across sleep/wake.
5. **Errors** — if the frontmost app cannot be controlled (no Accessibility permission, no window, app does not support full screen), no session starts and the user sees a short explanation.

## Acceptance Criteria
- [ ] With TextEdit/Xcode/VS Code frontmost, clicking the icon puts its window into full screen within ~1 s.
- [ ] Menu bar shows `25:00` and counts down each second.
- [ ] After sleeping the Mac for 5 minutes, remaining time is reduced by 5 minutes.
- [ ] Starting a session when Locus has no Accessibility permission does not lock anything and shows the permission prompt.
- [ ] Session/timer logic is covered by unit tests independent of AppKit.

## Open Questions
- Should the user confirm the target window before locking (e.g. "Lock *Xcode* for 25 min?")?
- Should the default duration be configurable in v1?
- What happens with apps that don't support native full screen — maximize instead, or refuse?
