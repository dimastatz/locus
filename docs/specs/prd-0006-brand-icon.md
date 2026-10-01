# PRD-0006: Brand Icon in the Menu Bar and Pop-up Windows

| Field      | Value                     |
|------------|---------------------------|
| Status     | Implemented (v1)          |
| Created    | 2026-10-01                |
| Supersedes | The monochrome menu bar icon in [PRD-0001](prd-0001-menu-bar-app.md) |
| Related    | [PRD-0001](prd-0001-menu-bar-app.md), [PRD-0005](prd-0005-hold-to-exit.md) |

## Overview
Locus should look like Locus wherever it appears. The menu bar icon keeps the original colors of the app icon, the blue-to-cyan gradient fish, instead of a monochrome silhouette. Every pop-up window Locus shows also carries the app icon.

## Problem
- The monochrome template icon blends in with system icons. The colored logo is the app's identity, and it's easier to spot at a glance whether Locus is running.
- The exit dialog has no branding, so it isn't obvious which app is asking "Are you sure you want to exit?" while you're in another app's full-screen window.

## Goals
- The menu bar icon is the original logo, colors unchanged, scaled to menu bar size.
- Every Locus pop-up window shows the app icon.

## Non-Goals
- Redesigning the logo.
- Changing the Finder/Dock app icon (`Locus.icns` already uses the original logo).

## Functional Requirements
1. **Menu bar icon, original colors**
   - Generated from `docs/images/locus-icon.png`: cropped to the fish and scaled to menu bar height (16 pt, 1× and 2×) with high-quality resampling.
   - Not a template image: macOS must not tint it.
   - **Idle:** the colored fish.
   - **Session active:** the colored fish with the red "!" alert badge at the top-right (from PRD-0001), plus the countdown.
2. **Pop-up windows show the app icon**
   - **Exit dialog** (PRD-0005): the app icon (64 pt) on the left of the title and message, macOS alert style.
   - **Alerts** (Accessibility permission needed, "Can't lock…", other errors): the app icon as the alert icon.
3. Outside the app bundle (`swift run`), the menu bar falls back to SF Symbol padlocks and pop-ups use the default application icon.

## Acceptance Criteria
- [ ] The menu bar shows the blue gradient fish in both light and dark menu bars, untinted.
- [ ] During a session the colored fish shows the red "!" badge and the countdown.
- [ ] The exit dialog shows the Locus icon.
- [ ] The Accessibility and error alerts show the Locus icon.

## Open Questions
- At 16 pt the gradient's fine detail is lost. If it reads poorly on some wallpapers or menu bar tints, should we add a thin outline or a simplified colored variant?
