# PRD-0009: DMG Package

| Field   | Value                     |
|---------|---------------------------|
| Status  | Implemented (v1)          |
| Created | 2026-10-02                |
| Related | [PRD-0001](prd-0001-menu-bar-app.md), [PRD-0006](prd-0006-brand-icon.md) |

## Overview
Ship Locus as a standard macOS disk image (`.dmg`) so people can install it the usual way: open the image and drag Locus into Applications.

## Problem
Locus is only available as source or a zipped `Locus.app`. A zip leaves the app wherever it was unpacked (often Downloads), which is not how Mac users expect to install apps, and macOS treats apps run from Downloads with extra suspicion.

## Goals
- One command builds an installable `.dmg` from the repository.
- Every tagged release has the `.dmg` attached.
- No tools beyond what ships with macOS and the Command Line Tools.

## Non-Goals
- Notarization and a Developer ID signature (needs a paid Apple Developer account).
- A custom background image or window layout for the mounted image.
- Auto-updates (e.g. Sparkle).
- A Homebrew cask.

## Functional Requirements
1. **Script:** `./scripts/build-dmg.sh [version]` builds `build/Locus-<version>.dmg`.
   - Builds `Locus.app` first with `./scripts/build-app.sh`. `SKIP_APP_BUILD=1` reuses an existing `build/Locus.app` and fails clearly if there isn't one.
   - Version defaults to `CFBundleShortVersionString` in `Support/Info.plist`. A leading `v` is stripped, so release tags like `v0.2.0` work.
2. **Contents:** `Locus.app` and an `Applications` link, so the app can be dragged straight in. The volume is named `Locus <version>`.
3. **Format:** compressed, read-only image (UDZO), made with `hdiutil`. The script verifies the image before it reports success.
4. **Signing:** the app inside keeps the signature from `build-app.sh`. When `CODESIGN_IDENTITY` is set, the image is signed with it too.
5. **CI:** every build uploads the `.dmg` next to the zipped app.
6. **Release:** pushing a `v*` tag attaches `Locus-<version>.dmg` to the GitHub release, and the release notes tell users how to install from it.

## Acceptance Criteria
- [ ] `./scripts/build-dmg.sh` on a clean checkout produces `build/Locus-0.2.0.dmg`.
- [ ] `./scripts/build-dmg.sh v0.2.0` produces `build/Locus-0.2.0.dmg`.
- [ ] Mounting the image shows `Locus.app` and `Applications`, and dragging Locus onto Applications installs it.
- [ ] `codesign --verify` passes on `Locus.app` inside the mounted image.
- [ ] `SKIP_APP_BUILD=1` without `build/Locus.app` fails with a clear error.
- [ ] CI artifacts and tagged releases include the `.dmg`.

## Open Questions
- Notarize once a Developer ID is available, so Gatekeeper doesn't block the first launch?
- Add a background image with an arrow pointing to Applications?
