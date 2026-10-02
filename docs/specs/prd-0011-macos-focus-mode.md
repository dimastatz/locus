# PRD-0011: macOS Focus During Sessions

| Field   | Value                     |
|---------|---------------------------|
| Status  | Implemented (v1)          |
| Created | 2026-10-02                |
| Related | [PRD-0002](prd-0002-focus-session.md), [PRD-0004](prd-0004-session-completion.md), [PRD-0005](prd-0005-hold-to-exit.md), [PRD-0010](prd-0010-completion-beep.md) |

## Overview
When a Locus session starts, turn on a macOS Focus (Do Not Disturb by default) so notifications from Mail, Slack and others stop interrupting. When the session ends, turn it off again.

## Problem
Locus keeps the user from switching away, but notification banners and sounds still break in. Each one is an invitation to go look, which leads to holding Exit or losing the thread. Users would have to remember to turn on Do Not Disturb themselves at the start, and remember to turn it off afterwards, or they miss messages for the rest of the day.

## Goals
- Notifications are silenced for exactly the length of the session.
- Off when the session ends, however it ends.
- Set up once; nothing to remember each session.

## Non-Goals
- Building a custom notification filter. Locus uses the user's own macOS Focus and its allowed people and apps.
- Changing Focus on the user's other devices. macOS may share Focus across devices ("Share across devices"); Locus neither forces nor prevents that.
- Creating or editing Focus modes.

## Technical Constraint
macOS has no public API for an app to turn a Focus on or off. The supported way is the Shortcuts app's **Set Focus** action, which can be run from Locus with `/usr/bin/shortcuts run "<name>"`. So Locus relies on two shortcuts on the user's Mac:
- **Locus Focus On**: Set Focus → *Do Not Disturb* (or the user's chosen Focus) → *On, until turned off*.
- **Locus Focus Off**: Set Focus → *Do Not Disturb* → *Off*.

The user creates both once in the Shortcuts app; each is a single Set Focus action. (v1 doesn't bundle `.shortcut` files: the Set Focus action's file format isn't documented, and an import can't be verified without user interaction.)

## Functional Requirements
1. **Setting:** a menu item **Turn On Do Not Disturb During Sessions**, shown when idle, with a checkmark when enabled. Off by default, and stored in `UserDefaults`.
2. **Setup:** enabling the setting checks for both shortcuts (`shortcuts list`). If either is missing, a Locus alert with the app icon (PRD-0006) explains why and how to create the missing ones, and **Open Shortcuts** opens the Shortcuts app. The setting is turned on only once both exist.
3. **Session start:** right after the window is locked (PRD-0002), run **Locus Focus On**.
4. **Session end:** run **Locus Focus Off** whenever a session ends:
   - the timer reaches zero (PRD-0004), *before* the completion beep and notification (PRD-0010), so they are heard;
   - early exit by holding Exit (PRD-0005);
   - the locked app quits or crashes;
   - Locus quits normally.
5. **Don't override the user:** Locus only turns off what it turned on: if the turn-on shortcut failed, it doesn't run the turn-off one. Whether a Focus was already on can't be read (see Open Questions), so v1 assumes it was off.
6. **Non-blocking:** shortcuts run in the background and never delay the lock or the countdown. A failure (shortcut missing, renamed, or errored) doesn't stop the session. The menu shows a short warning and suggests running setup again.
7. **Lightweight:** one process launch at the start and one at the end; nothing polls during the session.

## Acceptance Criteria
- [ ] With the setting on, starting a session turns on Do Not Disturb (moon in Control Center) within 2 seconds.
- [ ] At `00:00` Do Not Disturb turns off, then the beep and notification arrive (PRD-0010).
- [ ] Early exit and the locked app quitting both turn Do Not Disturb off.
- [ ] Quitting Locus during a session turns Do Not Disturb off.
- [ ] If the turn-on shortcut fails, the turn-off shortcut isn't run at the end.
- [ ] With the setting off (default), Locus never runs a shortcut.
- [ ] Deleting a shortcut mid-way shows a warning but the session still locks and counts down normally.
- [ ] The decision logic (when to turn Focus on/off, the "already on" rule) is in `LocusCore` and unit tested; running shortcuts lives in the AppKit target.

## Open Questions
- Ship ready-made `.shortcut` files so setup is one click per shortcut, instead of creating them by hand?
- If Do Not Disturb was already on before the session, it's turned off at the end. Have the turn-on shortcut check Get Current Focus first and report back?
- Let the user pick which Focus to use (Work, Personal…) instead of Do Not Disturb? That means editing the shortcut, or one shortcut per Focus.
- If Locus crashes or is force-quit, Do Not Disturb stays on. Should the next launch turn it off, or should **Locus Focus On** use "until a time" (the session end) as a safety net?
