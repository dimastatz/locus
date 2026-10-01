# PRD-0001: Menu Bar App

| Field   | Value                     |
|---------|---------------------------|
| Status  | Draft                     |
| Created | 2026-10-01                |
| Related | [PRD-0002](prd-0002-focus-session.md), [PRD-0003](prd-0003-exit-protection.md), [PRD-0004](prd-0004-session-completion.md) |

## Overview
Locus runs quietly in the background and lives in the macOS menu bar (the top toolbar). The menu bar icon is the only entry point to the app.

## Problem
A focus tool must be available instantly, without itself becoming another window to manage or another distraction in the Dock and app switcher.

## Goals
- Locus is always one click away from the menu bar.
- Locus adds no Dock icon, no main window, and no entry in the Cmd+Tab app switcher.
- Locus uses negligible CPU and memory while idle.

## Non-Goals
- A full settings window (out of scope for v1).
- Launch at login (candidate for a later PRD).

## User Stories
- As a user, I can see the Locus icon in the menu bar so I know the app is running.
- As a user, I can click the icon to start a focus session (see [PRD-0002](prd-0002-focus-session.md)).
- As a user, I can quit Locus from the menu when no session is active.

## Functional Requirements
1. The app is a menu-bar-only agent app (`LSUIElement = YES`): no Dock icon, no app-switcher entry.
2. On launch, an icon is added to the menu bar via `NSStatusItem` (AppKit) or `MenuBarExtra` (SwiftUI).
3. The icon reflects state:
   - **Idle** — the Locus fish logo in its original colors ([PRD-0006](prd-0006-brand-icon.md)).
   - **Session active** — the fish with a small red "!" alert badge, plus the remaining time (e.g. `24:13`).
4. Clicking the icon while idle starts a focus session on the currently active window, after confirmation ([PRD-0007](prd-0007-confirm-start.md)).
5. The menu (or a secondary click) contains:
   - **Start Focus Session** (idle only)
   - **Focus Duration** submenu (idle only, [PRD-0008](prd-0008-focus-duration.md))
   - **Quit Locus** (idle only — disabled while a session is active, see [PRD-0003](prd-0003-exit-protection.md))
6. On first launch, if Accessibility permission is not granted, Locus explains why it is needed and links to *System Settings → Privacy & Security → Accessibility*.

## Acceptance Criteria
- [ ] After launch, the Locus icon appears in the menu bar and no Dock icon appears.
- [ ] Locus does not appear in Cmd+Tab.
- [ ] Idle CPU usage stays at ~0%.
- [ ] Without Accessibility permission, clicking the icon shows the permission prompt instead of starting a session.
- [ ] "Quit Locus" is unavailable while a session is active.

## Open Questions
- Should a single left-click start a session immediately, or open a menu with a "Start" item? (Handwritten spec says click starts it.)
- ~~Should duration be selectable from the menu (e.g. 25 / 50 / 90 min) in v1?~~ Yes, see [PRD-0008](prd-0008-focus-duration.md).
