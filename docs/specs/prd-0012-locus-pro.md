# PRD-0012: Locus Pro

| Field   | Value                     |
|---------|---------------------------|
| Status  | Draft                     |
| Created | 2026-10-02                |
| Related | [PRD-0002](prd-0002-focus-session.md), [PRD-0005](prd-0005-hold-to-exit.md), [PRD-0008](prd-0008-focus-duration.md), [PRD-0009](prd-0009-dmg-package.md), [PRD-0011](prd-0011-macos-focus-mode.md) |

## Overview
Offer Locus in two editions. **Locus (free)** is the complete core habit: lock one app, count down, hold to exit. **Locus Pro** is a paid upgrade that makes Locus run the user's focus routine: lock a set of apps, start on a schedule, and show progress over time.

Positioning: *"Free locks one app. Pro runs your focus routine."*

## Problem
Locus has no way to fund ongoing development, signing and notarization. At the same time, power users outgrow the single-app lock: real deep work often spans an editor, a terminal and docs, and the people who want Locus most want it to be automatic and to show that it's working.

## Goals
- A free edition that is genuinely useful on its own, so people adopt and recommend Locus.
- A Pro edition with features people clearly see as worth paying for.
- One app: Pro unlocks features in place, with no separate download or reinstall.
- Upgrading is quick, and Pro works offline after activation.

## Non-Goals
- Removing or weakening anything free users have today.
- Ads, tracking, or selling data. Stats stay on the Mac.
- Teams/enterprise licensing, admin controls, or parental control.
- Mac App Store distribution (see Constraints).
- Specifying each Pro feature in full. Each one gets its own PRD before it's built; this PRD sets scope and the business model.

## Editions

### Free (everything Locus does today)
| Feature | PRD |
|---|---|
| Lock the active app in full screen with a countdown | [PRD-0002](prd-0002-focus-session.md) |
| Exit protection, hold Exit for 25 s | [PRD-0003](prd-0003-exit-protection.md), [PRD-0005](prd-0005-hold-to-exit.md) |
| Automatic release and notification at the end | [PRD-0004](prd-0004-session-completion.md) |
| Confirm before locking | [PRD-0007](prd-0007-confirm-start.md) |
| Focus duration presets and custom 5–240 min | [PRD-0008](prd-0008-focus-duration.md) |
| Completion beep | PRD-0010 |

### Pro, first release (the three headline features)
1. **Focus sets: lock a group of apps.**
   - Named sets of allowed apps, e.g. *Coding*: Xcode + Terminal + Safari; *Writing*: Pages + Notes.
   - During a session the user can switch freely between apps in the set; any other app triggers exit protection as today.
   - Pick the set when starting (start dialog, PRD-0007) or from the menu. The free single-app lock stays the default.
   - Why it sells: it removes the main limitation users hit, and it's easy to understand in one sentence.
2. **Schedules: start automatically.**
   - Recurring focus blocks, e.g. weekdays 9:00–11:00, each with a duration and an optional focus set.
   - At the start time Locus shows the start dialog with a short countdown. Skipping a scheduled session is allowed but counted (see Stats).
   - Why it sells: commitment the user doesn't have to remember turns Locus into a routine.
3. **Stats and streaks.**
   - Deep-work time per day and week, current and longest streak, sessions completed vs. ended early, top apps and sets.
   - A small window opened from the menu, plus a one-line summary in the menu ("3 h 20 min this week").
   - Stored locally only. Export to CSV.
   - Why it sells: proof that it's working; cheap to build because the data is already in `SessionController`.

### Pro, later releases (candidates, each needs its own PRD)
- **Let others know you're focusing:** Do Not Disturb during sessions ([PRD-0011](prd-0011-macos-focus-mode.md)), Slack status ("Focusing until 11:30"), and calendar blocks.
- **Stricter modes:** no early exit, a hold time that grows on each attempt, and keeping Locus from being quit during a session.
- **Pomodoro cycles:** automatic breaks and repeating sessions.
- **Website rules** inside an allowed browser (allowlist domains). High value but needs a browser extension or network filter.

Not planned as reasons to pay: ambient sounds, themes, custom beep sounds.

## Functional Requirements
1. **Single app, two editions:** the same `Locus.app` runs as free until a valid Pro license is activated.
2. **Upgrade entry points:**
   - A menu item **Upgrade to Pro…** (hidden once Pro is active).
   - Pro features are visible but marked with a **Pro** badge. Choosing one in the free edition shows a short dialog explaining it, with **Upgrade** and **Not Now**. Never nag during a session, and never more than once per feature per day.
3. **Activation:** **Enter License…** accepts a license key; activation needs the internet once, after which Pro works offline. The menu shows **Locus Pro** when active.
4. **Grace and failure:** if a license can't be re-validated (offline, server down), Pro keeps working. A revoked or refunded license falls back to free without losing data (sets, schedules and stats are kept and come back if Pro is reactivated).
5. **Feature gating** lives in `LocusCore` (an `Edition`/entitlements type) so it's unit tested; license validation details stay in the app target.
6. **Privacy:** no analytics. The only network calls are license activation and validation.

## Constraints
- **Not on the Mac App Store:** sandboxed apps can't control other apps' windows through the Accessibility API, which Locus depends on. Sales are direct.
- **Signing:** a paid app needs a Developer ID certificate ($99/year) and notarization, so it opens without Gatekeeper warnings. This also resolves the open question in [PRD-0009](prd-0009-dmg-package.md).
- **Updates:** paying users expect automatic updates (e.g. Sparkle). Needed before or with the first Pro release.

## Business Model (to decide)
- **Licensing of the code:** the repository is MIT-licensed, so anyone can build Pro features from source. Options:
  1. **Open core:** free core stays MIT; Pro features live in a closed-source module.
  2. **Pay for the ready-made app:** source stays open; customers pay for signed, notarized builds with updates and a license key. An honor-system key is easy to bypass but common for indie Mac apps.
  3. **Change the license** of future versions (e.g. source-available).
- **Price:** Mac users generally prefer a one-time purchase in the **$15–29** range (e.g. one major version, with updates for a year). A subscription ($3–5/month) only makes sense once Pro has ongoing services (sync across Macs, Slack and calendar integrations).
- **Store:** Paddle, Lemon Squeezy or Gumroad. They handle payments, VAT and license keys.
- **Trial:** a 14-day trial of Pro, or Pro features free for the first N sessions.

## Success Metrics
- Weekly active users of the free edition (from downloads and, if added, opt-in update checks; no tracking).
- Conversion from free to Pro, target 2–5% of active users.
- Refund rate below 5%.
- Pro users' sessions per week vs. free users'.

## Acceptance Criteria (for the first Pro release)
- [ ] Without a license, every feature listed under Free works exactly as before.
- [ ] Pro features show a Pro badge; choosing one opens the upgrade dialog, never during a session.
- [ ] Entering a valid key unlocks focus sets, schedules and stats without restarting; an invalid key shows a clear error.
- [ ] After activation, Pro works with the network turned off.
- [ ] Deactivating Pro keeps sets, schedules and stats, and reactivating restores them.
- [ ] Entitlement checks are unit tested in `LocusCore` with coverage at or above the 95% gate.
- [ ] The app is signed with a Developer ID and notarized.

## Open Questions
- Which code licensing option (open core, paid builds, or a license change)?
- One-time price or subscription, and how much?
- Trial: time-limited, session-limited, or none?
- Should stats be free (basic weekly total) with history and export in Pro, to show the value early?
- Which store (Paddle, Lemon Squeezy, Gumroad)?
- Do focus sets need per-app rules (e.g. allow Slack only for huddles), or is an app allowlist enough for v1?
