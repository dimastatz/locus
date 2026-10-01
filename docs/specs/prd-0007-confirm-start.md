# PRD-0007: Confirm Before Locking

| Field   | Value                     |
|---------|---------------------------|
| Status  | Implemented (v1)          |
| Created | 2026-10-01                |
| Amends  | [PRD-0002](prd-0002-focus-session.md): starting a session now asks for confirmation first |
| Related | [PRD-0005](prd-0005-hold-to-exit.md), [PRD-0006](prd-0006-brand-icon.md) |

## Overview
Before Locus locks a window, it asks **"Are you sure you want to start a focus session?"** and says what will happen: which app gets locked, for how long, and what it takes to leave early.

## Problem
Starting a session is one click, but leaving one takes a 25-second hold (PRD-0005). An accidental click on the menu bar icon, or a click while the wrong app is in front, would lock the user into the wrong window for 25 minutes. Making the user confirm keeps entering cheap, but never accidental.

## Goals
- No session starts by accident.
- The user knows exactly what they're committing to: the app, the duration, and how to get out.

## Non-Goals
- Choosing the duration in this dialog (a future PRD).
- A "Don't ask again" option (see Open Questions).

## Functional Requirements
1. **Trigger:** left-clicking the menu bar icon while idle, and **Start Focus Session** in the menu, both show the confirmation dialog instead of locking immediately.
2. **Validate first:** before showing the dialog, Locus checks Accessibility permission, that there is an app and window to lock, and that the window supports full screen. If a check fails, the existing error alert appears instead of the dialog, so the user never confirms a session that can't start.
3. **Dialog**
   - Title: **"Are you sure you want to start a focus session?"**
   - Message names the target app, the duration and the exit rule, e.g. *"Xcode will go full screen and stay locked for 25 minutes. To leave early, you'll have to hold Exit for 25 seconds."*
   - The Locus app icon on the left (PRD-0006).
   - Buttons: **Cancel** and **Start**. **Start** is the default (Return); **Esc** cancels.
   - Same floating, non-activating panel as the exit dialog, so the user's app stays frontmost while the dialog is open.
4. **Start** locks the window that was validated (PRD-0002). If that app quit while the dialog was open, nothing happens.
5. **Cancel** closes the dialog and returns focus to the user's app. No session starts.
6. Clicking the menu bar icon again while the dialog is open brings the existing dialog forward instead of opening a second one.

## Acceptance Criteria
- [ ] Clicking the menu bar icon while idle shows the dialog naming the frontmost app.
- [ ] **Start** or Return locks the window and starts the 25-minute countdown.
- [ ] **Cancel** or Esc closes the dialog; no session starts and the app keeps focus.
- [ ] Without Accessibility permission, the permission alert appears instead of the dialog.
- [ ] With an app that can't go full screen, the error appears instead of the dialog.
- [ ] Clicking the icon twice shows only one dialog.

## Open Questions
- Should there be a "Don't ask again" checkbox? It would bring back the risk of accidental locks, so it's left out of v1.
- Should the dialog let the user pick the duration (e.g. 25 / 50 / 90 min)?
