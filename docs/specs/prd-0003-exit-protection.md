# PRD-0003: Exit Protection (Password to Unlock)

| Field   | Value                     |
|---------|---------------------------|
| Status  | Partially superseded by [PRD-0005](prd-0005-hold-to-exit.md): the password unlock is replaced by hold-to-exit; exit detection still applies |
| Created | 2026-10-01                |
| Related | [PRD-0001](prd-0001-menu-bar-app.md), [PRD-0002](prd-0002-focus-session.md), [PRD-0004](prd-0004-session-completion.md) |

## Overview
While a focus session is active, attempting to exit full-screen mode (or otherwise leave the locked app) shows a prompt that requires a long password. Only after entering it is the session ended early.

## Problem
A lock that can be dismissed with one click is no lock at all. The goal is not to make leaving impossible, but to add enough deliberate friction to break the impulse to switch away.

## Goals
- Every escape route the user is likely to use impulsively is intercepted.
- Ending early requires a conscious, effortful action.

## Non-Goals
- Being tamper-proof against a determined user (force quit, killing the process, rebooting). Locus is a commitment device, not parental control.

## User Stories
- As a user in a session, when I click the green full-screen button or press Ctrl+Cmd+F, I'm asked for the password instead of leaving.
- As a user in a session, when I Cmd+Tab or click another app in the Dock, I'm brought back to the locked app and asked for the password.
- As a user who really needs to leave, I can type the password and end the session.

## Functional Requirements
1. **Detect exit attempts**, including:
   - Leaving full screen (observe `AXFullScreen` changes / window resize notifications via `AXObserver`).
   - Switching to another app (`NSWorkspace.didActivateApplicationNotification`).
   - Switching Spaces / Mission Control (`NSWorkspace.activeSpaceDidChangeNotification`).
   - Minimizing, hiding (Cmd+H) or closing the locked window.
   - Quitting the locked app.
   - Quitting Locus from its menu (disabled during a session).
2. **Respond to an attempt** — immediately return the locked window to the front and to full screen, then show the unlock prompt.
3. **Unlock prompt**
   - Modal panel above the locked window.
   - Secure text field; paste disabled.
   - **Cancel** returns to the session; **Unlock** checks the password.
   - Wrong password: show error, clear field, stay locked.
4. **Password**
   - A long password (minimum length to be decided, e.g. ≥ 32 characters).
   - Stored in the macOS Keychain, never in plain text.
5. **Correct password** ends the session early: lock released, timer stopped, menu bar icon back to idle.

## Acceptance Criteria
- [ ] Exiting full screen via button, shortcut, or menu re-enters full screen and shows the prompt.
- [ ] Cmd+Tab / Dock click to another app returns focus to the locked app and shows the prompt.
- [ ] Wrong password keeps the session running; correct password ends it.
- [ ] Pasting into the password field has no effect.
- [ ] The password is stored only in the Keychain.

## Open Questions
- How is the password defined — set once by the user on first launch, or a random phrase generated per session that must be retyped (stronger friction, no memorization)?
- If the locked app crashes or is force-quit, should the session end or Locus block other apps until the timer finishes?
- Should a few system apps (e.g. a phone call, Calendar alert) be allow-listed?
