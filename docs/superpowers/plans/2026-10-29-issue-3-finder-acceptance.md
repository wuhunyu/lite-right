# Issue #3 Finder Sync macOS 27 P0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare LiteRight for signed macOS 27 Finder context-menu acceptance by adding configurable Finder watch roots, reliable target selection, and truthful verification diagnostics.

**Architecture:** Keep Finder Sync's monitored roots in the existing App Group preference model; the host app edits roots, posts a session-scoped notification, and the Finder extension reapplies the normalized directory set. Resolve Finder menu kinds in the testable Swift core. Keep signature checks and real-Finder evidence separate from unsigned hosted CI.

**Tech Stack:** Swift 6, AppKit, SwiftUI, FinderSync, SwiftPM/XCTest, XcodeGen, macOS 27 Actions.

## Global Constraints

- Native-only, no SIP disabling / Finder injection / Electron / daemon.
- Five flat LiteRight actions; Finder controls actual placement and supported contexts.
- Folders outside monitored roots cannot be assumed supported by Finder Sync.
- CI builds are unsigned and do not prove Finder UI presence or TCC grant.
- Never mark Issue #3 complete without actual signed machine evidence in `docs/p0-matrix.md`.

---

### Task 1: Monitored Folder Normalization and Safe Selection

**Files:**
- Test: `LiteRightCore/Tests/LiteRightCoreTests/MonitoredFoldersTests.swift`
- Create: `LiteRightCore/Sources/LiteRightCore/MonitoredFolders.swift`
- Modify: `LiteRightCore/Sources/LiteRightCore/Models.swift`

**Interfaces:**
- `MonitoredFolders.normalize(_ paths: [String]) -> [String]`
- `MonitoredFolders.activeDirectoryURLs(_ paths: [String]) -> Set<URL>`
- `MonitoredFolders.didChangeNotification: String`
- `GeneralPreferences.normalized()` uses `MonitoredFolders.normalize`.

- [ ] **Step 1: Write failing tests** for duplicate roots, relative URLs, traversal, missing external volumes kept in preferences, nested monitored roots, existing valid folders.
- [ ] **Step 2: Run** `swift test --package-path LiteRightCore --filter MonitoredFoldersTests`; **expected RED**: `cannot find 'MonitoredFolders' in scope`.
- [ ] **Step 3: Implement** `normalize` with `URL(fileURLWithPath:).standardizedFileURL`, root exclusion and stable de-duplication; implement `activeDirectoryURLs` using `TargetResolver.validatedDirectory` and prune nested active roots.
- [ ] **Step 4: Run** `swift test --package-path LiteRightCore`; expected all SwiftPM tests pass on macOS.
- [ ] **Step 5: Commit** `test/feat(issue-3): normalize and validate Finder monitored roots`.

### Task 2: Finder Context Targeting

**Files:**
- Test: `LiteRightCore/Tests/LiteRightCoreTests/FinderMenuTargetTests.swift`
- Create: `LiteRightCore/Sources/LiteRightCore/FinderMenuTarget.swift`
- Modify: `LiteRightFinderExtension/FinderSync.swift`

**Interfaces:**
- `FinderMenuContext` cases: `items`, `container`, `sidebar`, `toolbar`.
- `FinderMenuTarget.resolve(context:targetedURL:selectedItemURLs:)` returns `ResolvedTarget`.

- [ ] **Step 1: Write tests** for blank background, clicked files, clicked folders, same-directory multi-select, different-directory multi-select, sidebar, unsupported URLs, toolbar.
- [ ] **Step 2: Run** `swift test --package-path LiteRightCore --filter FinderMenuTargetTests`; expected RED before implementation.
- [ ] **Step 3: Implement** pure resolver dispatch using `TargetResolver.resolve`; bridge `FIMenuKind` in `FinderSync.menu(for:)`, preserve action payload and disabled states.
- [ ] **Step 4: Run** SwiftPM tests and `xcodebuild ... build-for-testing` on macOS Actions.
- [ ] **Step 5: Commit** `feat(issue-3): cover Finder contextual menu target kinds`.

### Task 3: User-Controlled Monitored Directories and Cross-Process Refresh

**Files:**
- Modify: `LiteRightApp/Settings/GeneralSettingsView.swift`
- Modify: `LiteRightApp/Services/PreferenceViewModel.swift`
- Modify: `LiteRightFinderExtension/FinderSync.swift`
- Test: `LiteRightUITests/SettingsSmokeUITests.swift`

**Interfaces:**
- `PreferenceViewModel.update(_:) ` publishes `DistributedNotificationCenter` when normalized watched roots change.
- `FinderSync.reloadMonitoredDirectories()` assigns `FIFinderSyncController.default().directoryURLs` from active roots.

- [ ] **Step 1: Add GUI smoke assertion** for `Finder 监控` and `添加监控目录`; existing source lacks the action.
- [ ] **Step 2: Verify RED** by existing macOS XCUITest; missing control must fail.
- [ ] **Step 3: Implement** NSOpenPanel multi-directory chooser, remove action, path/availability labels and reset; add extension distributed notification observer and host notification poster only when roots change.
- [ ] **Step 4: Verify GREEN** with macOS XCUITest and compiled extension; do not interpret this as real Finder acceptance.
- [ ] **Step 5: Commit** `feat(issue-3): configure Finder roots and refresh extension`.

### Task 4: Signed-Bundle Diagnostics and Machine Acceptance

**Files:**
- Create: `ci/verify-signed-app.swift`
- Create: `docs/finder-real-machine-acceptance.md`
- Modify: `docs/p0-matrix.md`
- Modify: `docs/ci-runtime-tests.md`

**Interfaces:**
- `swift ci/verify-signed-app.swift /Applications/LiteRight.app`: fail without valid app + extension signatures, matching non-placeholder TeamIdentifier, and matching expected App Group entitlement.
- Document `pluginkit -m -i com.wuhunyu.literight.finder`, system settings verification and per-scene evidence collection.

- [ ] **Step 1: Prepare negative test**: unsigned CI bundle must fail `verify-signed-app.swift`; this is expected.
- [ ] **Step 2: Implement** codesign verification, team parity check and XML entitlement parse with Foundation.
- [ ] **Step 3: Document** developer-team signing, Finder extension enablement, supported/unsupported Finder contexts, terminal/TCC, and proof collection.
- [ ] **Step 4: Run** required macOS Actions for unsigned bundle; run signed verification only when actual signing is provisioned.
- [ ] **Step 5: Commit** `test/docs(issue-3): signed Finder acceptance diagnostics`.

### Task 5: Final Verification and PR

**Files:** `.github/workflows/macos-ci.yml`, `README.md`, `docs/p0-matrix.md` as needed.

- [ ] **Step 1:** Inspect Required test and actual Experimental GUI job conclusions, not only the workflow summary.
- [ ] **Step 2:** Ensure new UI smoke tests and core tests pass, bundle verification remains valid.
- [ ] **Step 3:** Open and review PR for Issue #3; link CI and explain pending physical-machine evidence in PR and issue.
- [ ] **Step 4:** Leave Issue #3 open and release No-Go if signed Finder menu screenshots / interaction records are absent.

## Real-Machine Acceptance Gate (external)

The human tester or a provisioned signed runner must provide macOS 27 OS/build + hardware + commit SHA + TeamIdentifier, matching App Groups and `codesign` checks, Finder extension enabled evidence, real menu snapshots, per-context test counts, Terminal.app/iTerm2 fresh-window checks, TCC deny cases, and restart persistence. Only after these can the P0 release status change from No-Go to Go.
