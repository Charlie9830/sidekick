# Production Release Build Automation

**Status:** Draft for review
**Date:** 2026-07-18
**Scope:** Automated production builds and publishing for desktop targets:
Windows (MSIX) and macOS (PKG). Web is excluded. Auto-update is explicitly
out of scope for this phase (see [Future work](#9-future-work)).

---

## 1. Goals

- One command per platform produces a signed, versioned installer and
  publishes it to GitHub Releases.
- Dependency pinning: the `mvr` package version used for a release is
  declared in a checked-in YAML file, not "whatever happens to be in the
  sibling directory".
- Reproducible preflight: a release build fails fast if the environment is
  wrong (dirty working tree, wrong mvr ref, version mismatch, missing
  signing material) rather than producing a mystery binary.
- The code repository stays free of release binaries; artifacts live in a
  separate, binaries-only GitHub repository.

### Non-goals (this phase)

- Auto-updater (Sparkle/Squirrel/custom). The release layout below is
  chosen so an updater can be bolted on later without restructuring.
- CI-hosted builds. Both pipelines run on local machines for now (Windows
  dev machine; a separate Mac for the macOS pipeline). Nothing in the
  design should *prevent* a later move to GitHub Actions.
- Microsoft Store / Mac App Store distribution.

---

## 2. Tooling: Fastforge

[Fastforge](https://fastforge.dev) (formerly `flutter_distributor`) is the
packaging backbone.

- Install: `dart pub global activate fastforge`
- Config: `distribute_options.yaml` at the project root defines named
  releases composed of package + publish jobs.
- Windows MSIX: Fastforge's `msix` target wraps the `msix` pub package we
  already use (`msix: ^3.16.12` is already a dev dependency), so the
  existing `msix_config` block in [pubspec.yaml](../pubspec.yaml#L160-L170)
  remains the source of truth for identity, display name, logo, and
  signtool options.
  > **Implementation note:** verify during implementation whether
  > Fastforge's per-target `windows/packaging/msix/make_config.yaml` is
  > required and whether it overrides or merges with `msix_config` in
  > pubspec. Whichever wins, config must live in exactly one place —
  > prefer pubspec since it already works.
- macOS PKG: Fastforge's `pkg` target builds the installer from the .app
  bundle. Signing and notarization are *not* Fastforge's job — they are
  explicit script steps (see §7).

### What Fastforge does not do

Fastforge has no concept of syncing a path-dependency to a git ref. The
`mvr` environment-setup step is our own script logic driven by our own
config file (§3).

---

## 3. Release configuration file

A single checked-in file, `release_config.yaml`, at the project root. This
is the file you edit when cutting a release against a new mvr version.

```yaml
# release_config.yaml
app:
  # Human name used in release titles. Version comes from pubspec.yaml,
  # never from this file.
  display_name: "It's Just a Phase"

dependencies:
  mvr:
    git: https://github.com/Charlie9830/mvr.git
    # A tag (preferred) or full commit SHA. Branch names are rejected by
    # the preflight check because they are not reproducible.
    ref: 7bf8167c26472701520aa773ef392ab61c61d99b
    # Where the checkout must live, relative to this repo's root, so that
    # pubspec's `path: ../mvr/` resolves. Overridable for CI later.
    path: ../mvr

publish:
  github:
    # The separate binaries-only repository.
    repo: Charlie9830/Phase
    draft: true          # create releases as drafts for manual review
    prerelease: false
```

Rules:

- **`dependencies.mvr.ref` must be a tag or commit SHA.** The mvr repo
  currently has no tags — start tagging it (`v0.1.0` for the current
  state) as part of adopting this process.
- The mvr version is *not* duplicated in this file; the pinned ref is the
  single identifier. The build log records the mvr `pubspec.yaml` version
  and commit SHA for traceability.

---

## 4. Versioning

- **Single source of truth:** `version:` in [pubspec.yaml](../pubspec.yaml#L19)
  (currently `1.1.1+1`).
- `msix_config.msix_version` (currently `1.1.1.0`) must equal
  `<pubspec build-name>.0`. Preflight *fails* on mismatch rather than
  silently rewriting a checked-in file; the error message states the
  expected value. (Optional later: a `--fix` flag that syncs it.)
- Release tag format: `v<build-name>` (e.g. `v1.1.1`) — used for the
  GitHub Release name/tag in the binaries repo and for the code repo tag.
- Both platforms must be built from the same code-repo commit for a given
  version. The macOS pipeline uploads into the *existing* release created
  by whichever platform published first (see §8).

---

## 5. Script layout

```
scripts/
  release/
    build_windows.dart      # entry point, Windows machine
    build_macos.dart        # entry point, macOS machine (authored later,
                            #   on the Mac, per this spec's §7)
    sync_dependencies.dart  # mvr checkout logic (shared, also runnable
                            #   standalone)
    common.dart             # shared helpers (config, process running)
release_config.yaml
```

- Scripts are Dart, run from the repo root with
  `dart run scripts/release/build_windows.dart [flags]`. They resolve
  against the app's own package config (`yaml` and `crypto` are dev
  dependencies), so `flutter pub get` must have run once beforehand.
  Config parsing and the mvr sync are shared between platforms;
  platform-specific steps (Windows cert-store lookup, Authenticode
  verification) shell out to one-line PowerShell commands.
- Entry points support:
  - `--dry-run` — run everything except `publish`.
  - `--skip-publish` — build only, leave artifacts in `dist/`.
  - `--force` — allow overwriting an already-uploaded release asset.
  - `--allow-dirty` — skip the clean-tree check (pipeline testing only).

---

## 6. Windows pipeline (`build_windows.dart`)

### 6.1 Preflight

Abort with a clear message if any check fails:

1. `flutter --version` succeeds; log the version into the build record.
2. Code repo working tree is clean (`git status --porcelain` empty) and
   the current commit is logged. *(Warn, don't fail, if not on `master` —
   release-from-branch is sometimes legitimate, but it should be loud.)*
3. `release_config.yaml` parses; `dependencies.mvr.ref` is a tag or SHA.
4. Version consistency check (§4): pubspec `version` ↔ `msix_version`.
5. Signing certificate with thumbprint
   `3526b5fc655d9e858cf5c3488a645e60c856fb5b` (from `signtool_options`) is
   present in the current-user certificate store. Fail early — signtool
   failing mid-build after a 5-minute compile is the current pain point
   this check removes.
6. `gh auth status` succeeds and has access to the binaries repo (skipped
   with `--skip-publish` / `--dry-run`).

### 6.2 Environment setup — mvr sync (`sync_dependencies.dart`)

Given `dependencies.mvr` from `release_config.yaml`:

1. If `<path>` (default `../mvr`) does not exist: `git clone <git> <path>`.
2. `git -C <path> fetch --tags origin`.
3. Working-tree safety: if the mvr checkout is dirty, **abort** — never
   discard someone's local work. The developer stashes/commits manually.
4. `git -C <path> checkout --detach <ref>`.
5. Verify `git -C <path> rev-parse HEAD` resolves and log the SHA plus the
   `version:` from mvr's pubspec.
6. Reminder printed at the end of the whole build: the sibling checkout is
   now on a detached HEAD; the script does **not** restore the previous
   branch (doing so silently would be more surprising than helpful).

### 6.3 Build

```powershell
flutter clean
flutter pub get
flutter test          # gate — release aborts on failure
fastforge package --platform windows --targets msix
```

- Output lands in `dist/` (Fastforge default), named per Fastforge
  convention; the script renames/normalizes to
  `its-just-a-phase-<version>-windows-x64.msix` for a stable, updater-
  friendly naming scheme.
- Signing happens inside the msix step via the existing
  `signtool_options` (SSL.com cert, RFC 3161 timestamp at
  `http://ts.ssl.com`).
- Post-build verification: `Get-AuthenticodeSignature` on the MSIX must
  report `Valid`.

### 6.4 Publish

See §8. On success, print the release URL and the artifact SHA-256.

---

## 7. macOS pipeline (spec only — implemented on the Mac)

This section is the contract for the Claude instance that will author
`build_macos.dart` on the Mac, reusing `common.dart` and
`sync_dependencies.dart`. Windows-side work does not block on it.

### 7.0 One-time platform bootstrap (not part of the build script)

The repo currently has **no `macos/` directory**. It must be created once
with `flutter create --platforms=macos .` and committed. Two hard
requirements from existing project history:

- `macos/Runner/AppDelegate.swift` requires manual window_manager
  overrides (`applicationShouldTerminateAfterLastWindowClosed`,
  `applicationShouldTerminate` returning `.terminateCancel` after
  `mainFlutterWindow?.performClose(nil)`) so ⌘Q routes through the
  unsaved-changes prompt (see
  [window-management-spec.md](window-management-spec.md)). Any
  `flutter create` invocation can clobber this file.
- **Build-script guard:** preflight greps `AppDelegate.swift` for
  `applicationShouldTerminate` and fails if the override is missing.

### 7.1 Preflight

Same checks as §6.1 (flutter, clean tree, config parse, version
consistency), plus:

1. AppDelegate override guard (above).
2. Signing identities present in the keychain:
   - `Developer ID Application: …` — signs the .app bundle.
   - `Developer ID Installer: …` — signs the .pkg.
3. A stored notarytool keychain profile exists
   (`xcrun notarytool history --keychain-profile <name>` succeeds).
   Profile name lives in `release_config.yaml` under a `macos:` section
   added when this pipeline is implemented — never store the app-specific
   password in the repo.
4. Hardened runtime + required entitlements present in
   `macos/Runner/*.entitlements` (notarization rejects binaries without
   hardened runtime).

### 7.2 Environment setup

`sync_dependencies.dart` — the same script as §6.2.

### 7.3 Build, sign, notarize

1. `flutter clean && flutter pub get && flutter test`
2. `fastforge package --platform macos --targets pkg` — the pkg maker's
   `macos/packaging/pkg/make_config.yaml` holds installer identity/paths.
3. Sign: .app with Developer ID Application (with hardened runtime,
   `codesign --options runtime`), .pkg with Developer ID Installer via
   `productsign` (verify whether Fastforge's pkg config can do this
   inline; explicit steps are acceptable and easier to debug).
4. Notarize: `xcrun notarytool submit <pkg> --keychain-profile <name>
   --wait` — fail the build on `status: Invalid`, printing the log URL.
5. Staple: `xcrun stapler staple <pkg>`.
6. Verify: `spctl --assess -vv --type install <pkg>` reports accepted.
7. Normalize name: `its-just-a-phase-<version>-macos-universal.pkg`
   (or `-arm64` if we only build for Apple silicon — decide on the Mac).

### 7.4 Publish

Same as §8; uploads into the existing `v<version>` release if the Windows
pipeline already created it.

---

## 8. Publishing to GitHub Releases

- **Binaries repo:** `Charlie9830/Phase`
  (https://github.com/Charlie9830/Phase). It needs at least one commit on
  its default branch, because GitHub Releases attach to a tag/commitish.
  The code repo never receives binary artifacts.
- **Mechanism:** the `gh` CLI, not Fastforge's GitHub publisher:

  ```powershell
  gh release create v<version> --repo <binaries-repo> --draft `
    --title "It's Just a Phase v<version>" --notes-file <notes> `
    dist/its-just-a-phase-<version>-windows-x64.msix
  # or, if the release already exists (second platform):
  gh release upload v<version> --repo <binaries-repo> <artifact>
  ```

  Rationale: Fastforge's GitHub publisher targets the *current* repo and
  gives little control over drafts/cross-repo publishing; `gh` handles
  the create-or-upload dance and cross-repo auth cleanly.
- **Idempotency:** script checks `gh release view v<version>` first —
  creates if missing, uploads (with `--clobber` only behind an explicit
  `-Force` flag) if present.
- **Release notes:** initially a minimal generated stub (version, date,
  commit SHA of code repo, mvr ref/SHA, artifact SHA-256 checksums).
  Drafts are reviewed and published manually from the GitHub UI.
- Also upload a `checksums-<version>.txt` (SHA-256 of each artifact) —
  cheap now, required later by any auto-updater.

---

## 9. Future work

- **Auto-updater:** the stable artifact naming, per-version tags, and
  checksums file above are the prerequisites. Candidates when the time
  comes: a simple in-app "new version available" check against the GitHub
  Releases API, or full Sparkle (macOS) / MSIX built-in updates via an
  `.appinstaller` feed (Windows).
- **CI migration:** both entry points are deliberately thin wrappers over
  deterministic steps so they can be lifted into GitHub Actions with
  macOS/Windows runners later. Signing material handling (cert in store,
  keychain profile) is the only machine-coupled part.
- **App icons:** the "Phi" concept (`design_docs/app_icons/concept-3-*`)
  was chosen. The Windows 512px export is wired into
  `msix_config.logo_path`; the macOS variant feeds the
  `AppIcon.appiconset` / `.icns` during §7.0 bootstrap.

---

## 10. Open questions

1. ~~**Binaries repo name**~~ — resolved: `Charlie9830/Phase`.
2. ~~**msix config precedence**~~ — resolved empirically: Fastforge
   *requires* `windows/packaging/msix/make_config.yaml` to exist, and
   passes its keys to the `msix` package as CLI flags, which override
   pubspec `msix_config`. We keep a minimal make_config.yaml
   (architecture only); pubspec remains the single source of truth.
3. **Test gate** — spec currently makes `flutter test` a hard gate for
   release builds. Acceptable, or should it be skippable via flag?
4. **macOS architecture** — universal binary vs Apple-silicon-only.
   Decide when the macOS pipeline is implemented.
5. **Draft releases** — spec defaults to `draft: true` with manual
   publish from the GitHub UI. Confirm this matches the intended flow.
