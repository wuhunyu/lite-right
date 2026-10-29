# CI Unnotarized Developer Preview Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate downloadable arm64 macOS 27 LiteRight preview installers from CI without Apple Developer credentials, with clear manual Gatekeeper approval instructions and no false Finder Sync acceptance claim.

**Architecture:** A separate macOS `xcode-27` workflow creates a Release app with `CODE_SIGNING_ALLOWED=NO`, then explicitly applies **ad-hoc** code signatures (no Developer Team or notarization) to the embedded Finder Sync extension and host app, preserving entitlements. The packager writes a `ditto` ZIP, read-only compressed DMG and SHA256 manifest; tests validate real bundle/signature/archives. Every qualifying run uploads a build artifact; a preview tag `preview-v*` publishes a GitHub **pre-release**. A deliberately marked main commit can create the initial one-off CI prerelease.

**Tech Stack:** GitHub Actions, Xcode 27 / Swift 6, XcodeGen, bash, codesign, ditto, hdiutil, shasum, gh CLI.

## Global Constraints

- Never disable Gatekeeper, SIP, quarantine globally, or forge Apple Team signatures.
- Artifact is ad-hoc signed, not Developer ID signed/notarized; `group.com.wuhunyu.literight` App Group may require authorizing provisioning and cannot be guaranteed.
- Finder Sync menu registration and all of Issue #3 stay No-Go until signed real-machine evidence exists.
- Use `preview-v*` for explicitly versioned GitHub prereleases; never present this as stable GA.
- No signing secrets are required and no credentials are embedded.

---

### Task 1: Developer-preview packaging contract

**Files:**
- Create: `ci/test-preview-package.sh`
- Create: `ci/package-preview.sh`
- Create: `.github/workflows/preview-distribution.yml`

**Interfaces:**
- `bash ci/package-preview.sh <source LiteRight.app> <destination directory> <package label>`
- Produces `LiteRight-<label>-macos-arm64-adhoc.zip`, matching `.dmg`, and `SHA256SUMS.txt`.
- `bash ci/test-preview-package.sh <destination directory> <package label>` inspects actual archives, signature and bundle.

- [ ] **Step 1: Add negative tests**: invoke packaging against nonexistent input; assert failure with diagnostics; add integration script assertions for archive names, `ditto` roundtrip, `codesign --verify --deep --strict`, and signed-only checker rejecting ad-hoc.
- [ ] **Step 2: Verify RED**: run the packaging workflow with tests but before implementing `ci/package-preview.sh`; expected error: `ci/package-preview.sh: No such file or directory`.
- [ ] **Step 3: Implement** packaging script: reject missing `.app` or `.appex`, copy app with `ditto`, ad-hoc sign extension then main using their respective entitlement files, verify signatures, create ZIP with `ditto -c -k --sequesterRsrc --keepParent`, create compressed DMG with `hdiutil create -format UDZO` and `Applications` alias, hash both.
- [ ] **Step 4: Verify GREEN**: macOS 27 Actions Release build, `swift ci/verify-app-bundle.swift` on copied app, `bash ci/test-preview-package.sh` verifies both archives and ad-hoc-only gate, and final artifact upload.
- [ ] **Step 5: Commit** `feat(ci): build unsigned Developer preview DMG and ZIP`.

### Task 2: GitHub prerelease and manual install documentation

**Files:**
- Create: `docs/unsigned-preview.md`
- Modify: `README.md`
- Modify: `docs/finder-real-machine-acceptance.md`
- Modify: `.github/workflows/preview-distribution.yml`

**Interfaces:**
- Artifacts on PR/main/manual workflow, github prerelease on `preview-v*` tag.
- One-off automatically created preview release on main push with `[publish-preview]` in commit message; subsequent releases opt-in via tag/manual workflow.

- [ ] **Step 1: Write documentation** that `ad-hoc` code signing is not Developer ID/notarization, how to safely verify SHA256 before dragging `LiteRight.app` to Applications, and Apple's `System Settings > Privacy & Security > Open Anyway` option after attempted open.
- [ ] **Step 2: Describe** Finder extension and App Group limitations (developer-team-authorized signing required for P0) and link Issue #3.
- [ ] **Step 3: Add** release job with least-privilege `contents: write`, artifact download, `gh release create ... --prerelease --notes-file docs/unsigned-preview.md`; tag guard to restrict releases to `preview-v*`.
- [ ] **Step 4: Validate** release job only runs on explicit tag or `[publish-preview]` on `main`, never on PR.
- [ ] **Step 5: Commit** `docs/release: clarify untrusted preview installation and signed Finder gate`.

### Task 3: CI validation, merge and first installer release

**Files:**
- `.github/workflows/preview-distribution.yml`, `ci/package-preview.sh`, `ci/test-preview-package.sh`.

- [ ] **Step 1:** Push feature branch and open PR; inspect the packaging workflow's required job and correct any macOS packaging errors from logs.
- [ ] **Step 2:** Validate both downloadable archives appear in the PR run, and that the signed-only test intentionally rejects the ad-hoc signature.
- [ ] **Step 3:** Merge via squash with `[publish-preview]` marker so the main push emits an initial GitHub prerelease; await release job confirmation.
- [ ] **Step 4:** Check `main` workflow result, release asset filenames and their actual visibility using GitHub APIs, then share the real links.
- [ ] **Step 5:** Keep Issue #3 **open** and update it to separate preview installation validation from signed Finder acceptance.

## Acceptance Criteria

- Independent workflow is green on macOS 27 arm64.
- ZIP and DMG contain a genuine app bundle with embedded Finder Sync extension and valid **ad-hoc** (not Developer ID) signature, and SHA256 manifest verifies.
- Artifact can be downloaded without code-signing secrets.
- GitHub release is explicitly marked prerelease with the caveats in its notes.
- No claim of signed Finder Sync/App Group functionality or Issue #3 closure.
