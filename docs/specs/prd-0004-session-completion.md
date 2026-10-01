# PRD-0004: Session Completion

| Field   | Value                     |
|---------|---------------------------|
| Status  | Draft                     |
| Created | 2026-10-01                |
| Related | [PRD-0001](prd-0001-menu-bar-app.md), [PRD-0002](prd-0002-focus-session.md), [PRD-0003](prd-0003-exit-protection.md) |

## Overview
When the countdown reaches zero, the lock is released automatically and the user is free to leave the app — no password needed.

## Problem
A focus session should end on its own terms. The reward for staying focused is a clean, frictionless exit.

## Goals
- The user clearly knows the session is over.
- The lock is fully removed — no lingering observers or prompts.

## Non-Goals
- Automatically starting break timers or repeating sessions (Pomodoro cycles) — future PRD.
- Session history/statistics.

## User Stories
- As a user, when my 25 minutes are up, I get a gentle notification that the session is complete.
- As a user, after the session ends, I can exit full screen and switch apps normally.

## Functional Requirements
1. When the timer reaches `00:00`:
   - Remove all exit-attempt observers set up in [PRD-0003](prd-0003-exit-protection.md).
   - Dismiss any open unlock prompt.
   - Reset the menu bar icon to idle.
2. Notify the user that the session is complete (user notification and/or subtle sound).
3. Leave the window in full screen — Locus does not force the user out; they exit when they choose.
4. If the Mac was asleep when the end time passed, the session completes immediately on wake.

## Acceptance Criteria
- [ ] At `00:00` a "Session complete" notification appears.
- [ ] After completion, exiting full screen and Cmd+Tab work with no prompt.
- [ ] Menu bar returns to the idle icon; "Start Focus Session" and "Quit Locus" are enabled again.
- [ ] If the end time passes during sleep, the session is completed on wake.

## Open Questions
- Should the notification offer "Start another session" / "Take a 5-min break" actions?
- Sound on completion: on by default or off?
