# PRD-0010: Completion Beep

| Field   | Value                     |
|---------|---------------------------|
| Status  | Implemented (v1)          |
| Created | 2026-10-02                |
| Amends  | [PRD-0004](prd-0004-session-completion.md): resolves the "sound on completion" open question |
| Related | [PRD-0011](prd-0011-macos-focus-mode.md) |

## Overview
Play a distinct "beep beep" when the focus timer runs out, so the user notices the session is over even when they are deep in the full-screen app and not looking at the menu bar.

## Problem
Today completion is announced with a notification and the default notification sound. That sound is easy to miss, is the same as every other app's notifications, and is silenced when a macOS Focus is on, which is exactly the situation Locus puts the user in ([PRD-0011](prd-0011-macos-focus-mode.md)).

## Goals
- The user hears, unmistakably, that the focus time is over.
- The sound is recognizably Locus's and different from ordinary notifications.

## Non-Goals
- Sounds at other moments (session start, early exit, the locked app quitting).
- Choosing a custom sound file.
- Warning beeps before the end (e.g. "5 minutes left").

## Functional Requirements
1. **When:** only when a session **completes** (the timer reaches `00:00`). No beep on early exit (PRD-0005) or when the locked app quits.
2. **Sound:** two short beeps ("beep beep") 0.3 s apart, using the built-in macOS `Morse` sound, so nothing extra is bundled.
3. **Played by Locus itself** (`NSSound`), not as the notification sound, so it plays even if notifications are off or silenced.
4. **No double sound:** the completion notification is posted without its own sound.
5. **Order:** if Locus turned on a macOS Focus for the session ([PRD-0011](prd-0011-macos-focus-mode.md)), it ends that Focus first, then beeps and posts the notification.
6. **Volume:** follows the system alert volume. If the Mac is muted, no sound plays.
7. **On wake:** if the session ended while the Mac was asleep (PRD-0004 FR4), it beeps once the session completes on wake.
8. The beep doesn't steal focus or bring Locus or any window to the front.

## Acceptance Criteria
- [ ] At `00:00` two short beeps play, followed by the "Focus session complete" notification.
- [ ] The notification itself makes no sound (no third chime).
- [ ] With notifications for Locus turned off in System Settings, the beep still plays.
- [ ] No beep on hold-to-exit early exit, or when the locked app quits.
- [ ] Muting the Mac silences the beep.
- [ ] The beep pattern (count, interval, sound name) is defined in `LocusCore` and unit tested; playback lives in the AppKit target.

## Open Questions
- Should there be a menu toggle to turn the beep off?
- Repeat the beeps until the user interacts, for people who walked away?
