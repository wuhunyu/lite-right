# Finder Sync missing contextual-menu triage and remediation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement task by task. Keep Issue #3 open pending physical-machine proof.

**Goal:** Fix the confirmed Finder Sync registration metadata defects in the ad-hoc developer preview; make installed-extension status reproducibly diagnosable; ensure sandboxed Finder Sync sends file actions to the host instead of attempting forbidden file writes.

**Architecture:** The extension is sandboxed, declares a valid FinderSync extension point and registers monitored roots. The native host remains the coordinator for all five operations; the extension sends short-lived, exactly-once request files via the existing App Group and opens the existing lite-right URL scheme. Installation diagnostics validate registration and activation separately from launch and do not silently change macOS security settings.

**Tech Stack:** macOS 27, Swift 6, XcodeGen, FinderSync, SwiftPM XCTest, bash, GitHub Actions xcode-27, PlugInKit.

## Global Constraints
- Native Swift/AppKit/SwiftUI only; no Electron, Finder injection, disabling SIP, disabling Gatekeeper or TCC.
- Ad-hoc signing is **not** Developer ID notarization; local registration is possible but not guaranteed on macOS 27.
- Extension signing must include `com.apple.security.app-sandbox = true` and App Group; do not grant a universal file-system sandbox exception.
- Preserve Settings UI and original five menu options/visibility/order.
- Nothing may claim Issue #3 is fully solved before actual signed desktop Finder observations.
- Keep read-only diagnosis separate from the explicit user-triggered `--enable` registration path.

---

### Task 1: Registration metadata, test-first

**Files:**
- Modify: `ci/verify-xcodegen-metadata.swift`
- Modify: `ci/test-preview-package.sh`
- Modify: `project.yml`
- Generated: `LiteRightFinderExtension/Info.plist`, `LiteRightFinderExtension/LiteRightFinderExtension.entitlements` (XcodeGen output)

**Interfaces:** Generated `NSExtension.NSExtensionAttributes` must be a dictionary; extension `com.apple.security.app-sandbox` must be true; signed .appex must include same sandbox claim.

- [ ] **Step 1** Add fail-fast checks to the generated-metadata checker for `NSExtensionAttributes` dictionary and Finder .appex `com.apple.security.app-sandbox`. Add signed .appex sandbox assertion to package validator.
- [ ] **Step 2** Push RED test commit and observe `xcode-27` workflow fail in `swift ci/verify-xcodegen-metadata.swift` with a matching reason; not a build unrelated error.
- [ ] **Step 3** Set `NSExtensionAttributes: {}` and `com.apple.security.app-sandbox: true` in the Finder target of `project.yml`.
- [ ] **Step 4** Verify generated metadata, core tests, release build and package validation GREEN on GitHub Actions.
- [ ] **Step 5** Commit with evidence in PR.

### Task 2: Read-only installed diagnostics and explicit refresh

**Files:**
- Create: `ci/diagnose-finder-sync.sh`
- Create: `ci/test-finder-sync-diagnostics.sh`
- Modify: `docs/unsigned-preview.md`
- Modify: `docs/finder-real-machine-acceptance.md`
- Modify: `.github/workflows/preview-distribution.yml`

**Interfaces:** `bash ci/diagnose-finder-sync.sh [--enable] [/Applications/LiteRight.app]`.
- Default mode never changes Finder or macOS permission settings; emits macOS version, installed app/appex paths, actual sandbox entitlement, signing identities, extension manager status, and a next-action message.
- Explicit `--enable` mode uses the installed canonical app, registers it with LaunchServices + `pluginkit -a`, requests enablement via `pluginkit -e use`, prints result; does not disable protections or delete user content. Restart Finder only after clear user opt-in or ask user to relaunch Finder themselves.

- [ ] **Step 1** Test non-existent path produces informative failure; show read-only mode leaves no registration action; `--help` includes commands.
- [ ] **Step 2** Run tests RED on initial absent script.
- [ ] **Step 3** Implement safe script; test `bash -n`, negative cases and shell smoke checks on macOS Actions.
- [ ] **Step 4** Document manual system settings and `pluginkit -m -v -i com.wuhunyu.literight.finder`; differentiate empty, +, !, - and multiple installed copies; don't claim + proves Finder UI.
- [ ] **Step 5** Commit.

### Task 3: Move sandbox-forbidden file operations to native host

**Files:**
- Modify: `LiteRightCore/Sources/LiteRightCore/RequestStore.swift`
- Test: `LiteRightCore/Tests/LiteRightCoreTests/RequestStoreTests.swift`
- Modify: `LiteRightFinderExtension/FinderSync.swift`
- Modify: `LiteRightApp/Services/OperationDispatcher.swift`

**Interfaces:** `RequestStore.save` and `claim` support all existing `MenuItemID` values, but no arbitrary or unknown actions; host validates the target directory before creating files, copying path, or opening terminal. Finder extension delegates all five actions using an existing short-lived request ID and `lite-right://run?id=<UUID>`.

- [ ] **Step 1** Add RED roundtrip tests for newText, newMarkdown, copyDirectoryPath plus existing terminal/toggle; retain expired/exactly-once validation.
- [ ] **Step 2** Observe red core suite on CI: `unsupportedAction` for new file / copy path requests.
- [ ] **Step 3** Implement minimal RequestStore allowlist extension and host dispatcher actions using `AtomicFileCreator`/`NSPasteboard`, validating target URLs.
- [ ] **Step 4** Refactor `FinderSync.performAction` to only write request to shared container and open the native host URI; no direct sandboxed filesystem writes. Run SwiftPM and Xcode UI tests.
- [ ] **Step 5** Commit.

### Task 4: Final CI + preview release

**Files:** `docs/p0-matrix.md`, `docs/unsigned-preview.md`, `README.md`.

- [ ] **Step 1** Validate production preview ZIP/DMG signatures and generated Info.plist (no more silent registration metadata failure).
- [ ] **Step 2** Verify Required+Experimental macOS Actions results separately; do not substitute simulated Finder registration for real menu use.
- [ ] **Step 3** Merge PR when CI green, with `[publish-preview]` marker to create new release.
- [ ] **Step 4** Verify release has actual DMG, ZIP and SHA256SUMS, and direct links; update Issue #3 with root cause, code fix and remaining machine checks.
- [ ] **Step 5** User follows diagnostics on installed machine, captures `pluginkit` state and Finder right-click screenshot; only then consider Issue #3 complete.

## Reference Evidence
- User screenshot: LiteRight Settings works; Finder background and file context menus contain no LiteRight actions.
- Previous CI logged `pluginkit -a` success but empty `pluginkit -m -i` output on hosted unsigned macOS.
- Checked-in Finder extension entitlements include only App Group; missing sandbox.
- Generated Finder extension plist lacks documented `NSExtensionAttributes`.
- Apple Finder Sync Guide: https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html
- Public sandboxed ad-hoc reference: https://github.com/elisamuel40/finder-new-text-file/blob/main/install.sh
