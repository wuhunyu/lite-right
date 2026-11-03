# LiteRight 1.0.0-preview Product Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Deliver LiteRight 1.0.0-preview with matching brand identity, a simplified Finder extension settings surface, and meaningful privacy-preserving diagnostics, without changing existing Finder operations.

**Architecture:** Keep the Finder Sync and host/preview IPC unchanged. Move the extension-management UI to General Settings, generate a monochrome brand asset through the existing SVG export pipeline, and centralize display-version/diagnostic formatting in the testable LiteRightCore module.

**Tech Stack:** Swift 6, SwiftUI, AppKit, FinderSync, XcodeGen, macOS 27 runner.

## Global Constraints

- User-facing version is exactly `1.0.0-preview`; Apple `CFBundleShortVersionString` is `1.0.0` and the channel key is `preview`.
- Preserve four actions: TXT, Markdown, open selected terminal, copy absolute path.
- Do not remove Apple Events usage disclosure: Terminal.app/iTerm2 still receive AppleScript.
- No credentials, usernames or full file paths in copied diagnostics.
- Keep ad-hoc preview IPC and signed App Group IPC unchanged.

---

### Task 1: Version and diagnostic model

**Files:** Create `LiteRightCore/Sources/LiteRightCore/ReleaseInfo.swift`; create `LiteRightCore/Tests/LiteRightCoreTests/ReleaseInfoTests.swift`; modify `LiteRightApp/Settings/AboutView.swift`.

**Interfaces:** `ReleaseInfo.displayVersion(marketingVersion:channel:)` returns e.g. `1.0.0-preview`; `ReleaseInfo.diagnosticSummary(displayedVersion:build:operatingSystem:architecture:finderExtensionEnabled:transport:monitoredFolderCount:)` returns a privacy-safe multiline string.

- [ ] Write the three release/diagnostic regression tests before code.
- [ ] Run macOS Swift tests and confirm the new ReleaseInfo identifier fails to compile (RED).
- [ ] Add `ReleaseInfo` and wire AboutView to real bundle/runtime data (GREEN).
- [ ] Run `swift test --package-path LiteRightCore` and review all tests.
- [ ] Commit implementation.

### Task 2: Finder and permissions settings UX

**Files:** Modify `LiteRightApp/Settings/SettingsRootView.swift`, `LiteRightApp/Settings/GeneralSettingsView.swift`; delete `LiteRightApp/Settings/PermissionsView.swift`.

**Interfaces:** The General Settings screen contains one Finder Sync status and the native management button; no independent Permissions page, App Group status, backup shortcut, or unverified automation indicator.

- [ ] Add a GUI smoke test for the Finder extension management control in General Settings and no separate Permissions tab.
- [ ] Run macOS UI tests (RED).
- [ ] Move Finder Sync management to General and remove redundant permissions page (GREEN).
- [ ] Preserve TerminalLauncher and `NSAppleEventsUsageDescription`; run GUI smoke tests.
- [ ] Commit implementation.

### Task 3: Brand template menu bar icon

**Files:** Modify `tools/export-icons.py`, `LiteRightApp/Services/StatusBarController.swift`; create `LiteRightApp/Assets.xcassets/MenuBarIcon.imageset/Contents.json`.

**Interfaces:** `NSImage(named: "MenuBarIcon")`, configured as a macOS template icon. Source SVG remains `assets/menubar/LiteRightMenuBar.svg`.

- [ ] Add an export-pipeline asset check in macOS packaging workflow.
- [ ] Confirm the generated asset is initially missing (RED).
- [ ] Export 18/36px images into the asset catalog and set the status item to the named template image (GREEN).
- [ ] Run asset and app-bundle CI checks.
- [ ] Commit implementation.

### Task 4: Release metadata and validation

**Files:** Modify `project.yml`, generated `LiteRightApp/Resources/AppInfo.plist`, `ci/verify-app-bundle.swift`, `.github/workflows/preview-distribution.yml`, `README.md`, `CHANGELOG.md`.

**Interfaces:** Both app and Finder extension market version `1.0.0`, app channel `preview`; preview builds pass a numeric `CURRENT_PROJECT_VERSION` from the Actions run number. About/diagnostics show the channel.

- [ ] Add CI validation that app and extension share a version/build and channel.
- [ ] Verify it fails against the old 0.1.0 metadata (RED).
- [ ] Update XcodeGen metadata and CI preview build invocation (GREEN).
- [ ] Run macOS native tests, build checks and preview packaging; inspect failures.
- [ ] Commit and submit a pull request for review.

### Acceptance checklist

- [ ] Top menu bar icon matches LiteRight's SVG icon language and follows macOS light/dark tinting.
- [ ] General Settings exposes Finder extension manager without debug-only states.
- [ ] Terminal.app/iTerm2 operations still work and can request Automation permission.
- [ ] Version shown as `1.0.0-preview`; installer marketing version remains `1.0.0`.
- [ ] Diagnostics include actual architecture/Finder state/transport and no full paths.
- [ ] macOS CI & ad-hoc preview packaging pass; real-machine Finder smoke test is separately identified as a user acceptance step.
