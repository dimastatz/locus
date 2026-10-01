# PRD-0005: Hold to Exit

| Field      | Value                     |
|------------|---------------------------|
| Status     | Implemented (v1)          |
| Created    | 2026-10-01                |
| Supersedes | The password unlock in [PRD-0003](prd-0003-exit-protection.md) (exit detection in PRD-0003 still applies) |
| Related    | [PRD-0001](prd-0001-menu-bar-app.md), [PRD-0002](prd-0002-focus-session.md), [PRD-0004](prd-0004-session-completion.md) |

## Overview
Replace the long unlock password with a confirmation dialog. When the user tries to leave a focus session early, Locus asks **"Are you sure you want to exit?"** and shows two buttons: **Go Back** and **Exit**. Exit only works if the user **presses and holds it for 25 seconds**.

## Problem
The password adds friction but has costs of its own:
- The user has to choose, remember and safely store a 32-character password.
- Typing is a skill. With practice a long password becomes muscle memory, which stops it from slowing anyone down.
- A forgotten password leaves the user locked out until the timer ends.

What actually needs blocking is the *unconscious* switch, the reflexive ⌘Tab to check Slack. Holding a button for 25 seconds gives the user time to notice what they're doing and change their mind, with nothing to set up or remember.

## Goals
- Every early exit is a deliberate choice, made over a sustained period of time.
- Going back to work is always one click (or one key) away.
- No secret to set up, remember or store.

## Non-Goals
- Stopping a user who has decided to quit. Like PRD-0003, Locus is a commitment device, not parental control.
- Changing *how* exit attempts are detected. That stays as in PRD-0003.

## User Stories
- As a user who ⌘Tabs out of habit, I see "Are you sure you want to exit?" and click **Go Back** to continue working.
- As a user who really has to leave (an incident, a meeting), I hold **Exit** for 25 seconds and the session ends.
- As a user holding **Exit**, I can see my progress and can let go at any moment to stay in the session.

## Functional Requirements
1. **Trigger:** every exit attempt detected per PRD-0003 (leaving full screen, ⌘Tab, ⌘Q, ⌘H, ⌘M, switching Spaces, activating another app, closing or minimizing the window), as well as **End Session Early…** in the menu, opens the exit dialog. The dialog replaces the password prompt.
2. **Dialog**
   - Title: **"Are you sure you want to exit?"**
   - Supporting text shows what is at stake, e.g. *"14:32 of focus left on Xcode."*
   - Two buttons: **Go Back** and **Exit**.
   - Appears over the locked app's full-screen Space without switching Spaces (same panel behavior as today's unlock prompt).
3. **Go Back**
   - Closes the dialog and returns focus to the locked window. The session continues.
   - Go Back is the default action: Return and Esc both choose Go Back.
4. **Exit (hold to confirm)**
   - A click does nothing except show a hint: *"Hold for 25 seconds to exit."*
   - The user has to **press and hold** the mouse or trackpad button on Exit for **25 seconds** (configurable constant, see Open Questions).
   - The button shows progress while held: a fill or ring plus the seconds remaining.
   - The hold **resets to zero**, not pauses, if the user:
     - releases the button;
     - drags the pointer off the button;
     - lets the dialog lose key status, or closes it.
   - Keyboard activation can't complete the hold. Holding Space or Return doesn't count, so key auto-repeat can't be used to get around it.
   - After 25 seconds of continuous holding, the session ends early (end reason: unlocked/early exit) and the lock is released.
5. **The session timer keeps running** while the dialog is open. If the session completes during the hold, the dialog closes and the session ends normally (PRD-0004).
6. **Password removal:** the password setup flow, the Keychain item and **Change Unlock Password…** go away. Starting a session no longer needs any setup beyond Accessibility permission.

## Acceptance Criteria
- [ ] Any exit attempt during a session shows "Are you sure you want to exit?" with Go Back and Exit.
- [ ] Go Back, Return and Esc close the dialog and return to the locked window; the session continues.
- [ ] Clicking Exit without holding doesn't end the session and shows the hold hint.
- [ ] Holding Exit for 24 seconds and then releasing doesn't end the session, and progress resets to 0.
- [ ] Dragging off the button partway through resets progress.
- [ ] Holding Space/Return on a focused Exit button doesn't end the session.
- [ ] Holding Exit for 25 seconds ends the session and releases the lock.
- [ ] If the timer reaches 0 while the dialog is open, the session completes normally.
- [ ] No password is asked for at any point; no Keychain item is created.
- [ ] The hold-progress logic (start, reset, completion at 25 s) is unit tested in `LocusCore` with an injected clock.

## Open Questions
v1 resolves migration (the legacy Keychain item is deleted at launch) and fixes the duration at 25 s. Escalation and an accessibility alternative remain open.

- **Hold duration.** 25 seconds is the proposed default. Should it be user-configurable, and should there be a minimum (e.g. never below 15 s)?
- **Escalation.** Should repeated early exits take longer to confirm, e.g. 25 s for the first early exit of the day and 60 s for later ones?
- **Accessibility of the gesture.** Users who can't comfortably hold a click for 25 s (motor impairments) need an alternative. One option is a "hold" toggle that keeps progressing until clicked again, as long as the pointer stays on the button.
- **Migration.** The existing Keychain item from the password version should be deleted on first launch of the new version.
