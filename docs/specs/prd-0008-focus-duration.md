# PRD-0008: Focus Duration Setting

| Field   | Value                     |
|---------|---------------------------|
| Status  | Implemented (v1)          |
| Created | 2026-10-01                |
| Amends  | [PRD-0002](prd-0002-focus-session.md): the session length is no longer fixed at 25 minutes |
| Related | [PRD-0001](prd-0001-menu-bar-app.md), [PRD-0007](prd-0007-confirm-start.md) |

## Overview
Let the user choose how long a focus session lasts. 25 minutes stays the default, but people work in different rhythms: 15 minutes for a quick task, 50 or 90 minutes for deep work.

## Problem
Every session is fixed at 25 minutes. Users who want longer deep-work blocks have to restart Locus repeatedly, which breaks the focus Locus is meant to protect. Users who want a short sprint are locked in longer than they intended.

## Goals
- Pick a session length in one or two clicks from the menu bar.
- The choice is remembered across launches.
- The user always sees which duration the next session will use.

## Non-Goals
- Changing the length of a session that is already running.
- Breaks or repeating cycles (Pomodoro), which may come in a future PRD.
- Changing the 25-second hold-to-exit time (PRD-0005), which is separate.
- A full settings window.

## Functional Requirements
1. **Focus Duration submenu** in the menu bar menu (idle only, hidden during a session):
   - Presets: **15, 25, 45, 60, 90 min**, with a checkmark on the current one.
   - **Custom…** opens a dialog to type any whole number of minutes. When a custom value is active, the item reads **Custom (50 min)…** and has the checkmark.
2. **Custom dialog**
   - Title **Focus Duration**, a text field pre-filled with the current value, **Cancel** and **Save**. Save is the default (Return); Esc cancels.
   - Accepts **5–240 minutes**. Input like `50`, `50 min` or `50 minutes` is accepted.
   - Invalid input (out of range, not a whole number) shows an error and keeps the dialog open.
   - The Locus app icon on the left; the same floating panel as the other dialogs (PRD-0006).
3. **Default:** 25 minutes when nothing (or nothing valid) is stored.
4. **Persistence:** stored in `UserDefaults` and kept across launches.
5. **Used everywhere:**
   - The menu item reads **Start Focus Session (N min)**.
   - The start confirmation (PRD-0007) names the chosen duration.
   - The session runs for the chosen duration.
   - The duration is read once when the start dialog opens, so the dialog and the session always agree.

## Acceptance Criteria
- [ ] The menu shows Focus Duration with 15/25/45/60/90 and 25 checked on first launch.
- [ ] Choosing 45 updates the checkmark, the Start Focus Session label and the start dialog text.
- [ ] Custom… accepts 50 and the menu then shows "Custom (50 min)…" with a checkmark.
- [ ] Custom… rejects 4, 241, `abc` and `2.5` with an error.
- [ ] The chosen duration survives quitting and relaunching Locus.
- [ ] A session started with 45 minutes shows `45:00` in the menu bar and ends after 45 minutes.
- [ ] Focus Duration isn't shown during a session.
- [ ] Validation, parsing and persistence are unit tested in `LocusCore`.

## Open Questions
- Should the start dialog (PRD-0007) also offer the presets, for a one-off duration?
- Should very long sessions (over 2 hours) prompt a reminder to take a break?
