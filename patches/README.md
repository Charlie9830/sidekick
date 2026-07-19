# Platform patches

`macos/` and `windows/` are generated directories. Any hand-made edit in
them — the window_manager Quit override in `AppDelegate.swift`, the
release entitlements — is lost the moment those folders are regenerated.
This directory holds the authoritative copy of every such file, and the
release scripts restore them on every build.

## Layout

```
patches/<platform>/<path relative to the repo root>
```

The first segment picks which patches a build applies: `build_macos.dart`
reads `patches/macos/` only, `build_windows.dart` reads `patches/windows/`
only. Everything after it is the destination path, verbatim.

A bucket that does not exist is not an error — the build reports that
there is nothing to apply and carries on. `patches/windows/` is absent for
that reason; create it when Windows has its first patch.

So the macOS AppDelegate lives at:

```
patches/macos/macos/Runner/AppDelegate.swift
   |     |     └── the real path it is copied to
   |     └──────── platform bucket
   └────────────── this directory
```

The doubled `macos` is deliberate. Because the destination is a full
repo-relative path rather than one relative to `macos/`, a patch can
target a file anywhere in the repo, not only inside the platform folder.

## When patches are applied

Immediately after `flutter clean` + `flutter pub get`, before the build.
Each file is compared by SHA-256 against its destination and copied only
if they differ, so the build log distinguishes three cases:

- `patched` — the destination existed but had drifted; it was overwritten.
- `restored (missing)` — the destination was gone entirely.
- `skipped (identical)` — already up to date.

A run that reports anything other than `skipped` on a clean tree means the
platform folder was regenerated since the last build.

## Adding a patch

1. Make the edit in the real file (e.g. `macos/Runner/Foo.swift`) and get
   it working.
2. Copy it to the mirrored path under `patches/<platform>/`.
3. Commit both. They are expected to stay byte-identical.

`test/patches_test.dart` enforces step 2: any normal `flutter test` run
fails if a patch and the file it patches have diverged, so a direct edit
to a patch-managed file is caught at once rather than being silently
reverted at release time.

To apply the tree by hand without running a full release:

```sh
dart run scripts/release/apply_patches.dart macos
```
