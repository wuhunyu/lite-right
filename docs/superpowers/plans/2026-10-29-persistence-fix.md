# LiteRight Local Preferences Durability & Shared Sync Failure Implementation Plan

> **For agentic workers:** REQUIRED-SUB-SKILL: Use test-driven-development and executing-plans. Steps use checkbox (`- [ ]`) for tracking.

**Goal:** Fix verified macOS 27 `cfprefsd` App Group preference write denials causing all settings to reset, without claiming that ad-hoc signing can authorize Finder extension sharing.

**Architecture:** Main app persists `GeneralPreferences` to its own Application Support/LiteRight/preferences.json via atomic read/write, completely independent of the App Group. It attempts to mirror preferences to App Group for Finder Sync when authorized, explicitly recording failure. Finder extension continues to use App Group while Issue #3 remains blocked by signed-machine verification.

**Tech Stack:** Swift 6, Foundation, SwiftUI, XCTest, XcodeGen/macOS 27 Actions.

## Constraints

- Evidence: `cfprefsd` repeatedly logged `rejecting write ... Domain: group.com.wuhunyu.literight ... from process LiteRight ... requires user-preference-write or file-write-data sandbox access`; `defaults read` reported no group domain.
- Never remove macOS sandbox, SIP, Gatekeeper, or alter user filesystem ACLs as a workaround.
- Main app must save every menu, terminal, Dock, and monitoring preference even if App Group is denied; do not report Finder sharing as successful.
- Preserve existing FinderSync request bridge and menu kinds; work is limited to persistence & truthful diagnostics.
- CI test success cannot prove actual ad-hoc App Group sharing on user's Mac.

---

### Task 1: Test independent host persistence and explicit shared-domain failure

**Files:**
- Create: `LiteRightCore/Tests/LiteRightCoreTests/HostPreferencesStoreTests.swift`
- Modify: `LiteRightCore/Tests/LiteRightCoreTests/PreferencesTests.swift`

**Interfaces:**
- `HostPreferencesStore(fileURL: URL, legacy: @escaping () -> GeneralPreferences)`
- `load() throws -> GeneralPreferences`; `save(_ preferences: GeneralPreferences) throws`
- `SharedPreferences.save` throws if `UserDefaults.synchronize()` returns false.

- [ ] Write HostPreferencesStore tests for atomic file roundtrip with fresh instance, no file -> legacy fallback, corrupted JSON -> explicit error, invalid parent path -> error.
- [ ] Write `DeniedDefaults: UserDefaults` overriding `synchronize() -> false`, assert SharedPreferences.save throws.
- [ ] Run `swift test --package-path LiteRightCore` via macOS CI and observe RED for missing HostPreferencesStore and silent synchronize failure.
- [ ] Implement Store as Foundation file in `LiteRightCore/Sources/LiteRightCore/HostPreferencesStore.swift`. Use `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LiteRight/preferences.json")` default; `JSONEncoder().encode(value.normalized()).write(to: fileURL, options: .atomic)`; `Data(contentsOf: fileURL)` and `JSONDecoder().decode` on load. Unknown saved JSON must throw, not reset silently.
- [ ] Change SharedPreferences.save to `guard defaults.synchronize() else { throw LiteRightError.operationFailed("App Group 共享偏好设置写入被系统拒绝。") }`.
- [ ] Run SwiftPM, ensure GREEN, commit.

### Task 2: Wire host & notify users of failed Finder sharing

**Files:**
- Modify `LiteRightApp/Services/PreferenceViewModel.swift`
- Modify `LiteRightApp/LiteRightApp.swift`
- Modify `LiteRightApp/Services/OperationDispatcher.swift`
- Modify `LiteRightApp/Settings/SettingsRootView.swift`
- Modify `LiteRightApp/Settings/PermissionsView.swift`

**Interfaces:**
- Host app reads only `HostPreferencesStore` for its own canonical settings.
- ViewModel does `try local.save(updated)` before updating displayed value; then best-effort `try shared.save(updated)` and sets `sharedSyncWarning` on failure.
- No false generic "Unable to save" alert when local save succeeds; visible lightweight message clarifies local saved / Finder sync failed.
- Permissions view replaces misleading "container URL exists" conclusion with an actual writable prefs check and caveat.

- [ ] Update host loading code and dispatcher to HostPreferencesStore.
- [ ] Maintain old values if local save fails; show actionable error. If shared mirror fails, retain local save and show warning rather than resetting controls.
- [ ] Add GUI smoke test for persisted menu toggle across app relaunch (using existing XCUITest and temporary test settings, restore original on exit).
- [ ] Build/test on macOS CI; commit.

### Task 3: Verification and release scope

**Files:**
- Modify `docs/p0-matrix.md` and `docs/unsigned-preview.md`

- [ ] Verify Swift unit tests, actual app build and GUI tests on PR; inspect both Required and Experimental job conclusions.
- [ ] Update Issue #3 with precise `cfprefsd` denial evidence and scope of fix.
- [ ] Merge to main, publish developer preview after green CI, verify actual DMG/ZIP assets and checksums.
- [ ] Do not close Issue #3 or claim Finder actions work; signed or alternative IPC architecture is separately required for App Group sharing under ad-hoc distribution.
