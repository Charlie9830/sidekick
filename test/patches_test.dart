/// Guards the `patches/` tree against drifting from the working tree.
///
/// The release scripts copy `patches/<platform>/...` over the generated
/// platform folders at build time, so the patch tree is the copy of
/// record. Editing `macos/Runner/AppDelegate.swift` directly works
/// locally and is then silently reverted at release time — this test is
/// what turns that into an immediate, obvious failure.
///
/// See patches/README.md.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('patches/', () {
    final patchesDir = Directory('patches');

    test('every patch matches the file it patches', () {
      if (!patchesDir.existsSync()) return;

      final mismatches = <String>[];
      for (final bucket in patchesDir.listSync().whereType<Directory>()) {
        for (final patch in _patchFiles(bucket)) {
          final relativePath = p.relative(patch.path, from: bucket.path);
          final target = File(relativePath);

          if (!target.existsSync()) {
            mismatches.add('$relativePath is missing from the working tree');
          } else if (!_sameBytes(patch, target)) {
            mismatches.add(
              '$relativePath differs from ${p.relative(patch.path)}',
            );
          }
        }
      }

      expect(
        mismatches,
        isEmpty,
        reason:
            'The patch tree and the working tree have diverged:\n'
            '  ${mismatches.join('\n  ')}\n\n'
            'Whichever copy is correct, both must match. To push the patch '
            'tree onto the working tree:\n'
            '  dart run scripts/release/apply_patches.dart <platform>\n'
            'If instead you edited the working tree directly, copy your '
            'change back into patches/. See patches/README.md.',
      );
    });

    test('patch destinations stay inside the repo', () {
      if (!patchesDir.existsSync()) return;

      for (final bucket in patchesDir.listSync().whereType<Directory>()) {
        for (final patch in _patchFiles(bucket)) {
          final relativePath = p.relative(patch.path, from: bucket.path);
          expect(
            p.isRelative(relativePath) && !relativePath.startsWith('..'),
            isTrue,
            reason:
                '$relativePath would be written outside the repo root. Patch '
                'paths are repo-relative by construction; this one is not.',
          );
        }
      }
    });
  });
}

/// Real patch content in [bucket], excluding directory metadata.
///
/// Mirrors the exclusions in `scripts/release/apply_patches.dart`; the two
/// lists must agree or the test would police files the build never copies.
Iterable<File> _patchFiles(Directory bucket) => bucket
    .listSync(recursive: true)
    .whereType<File>()
    .where(
      (file) =>
          !const ['.DS_Store', '.gitkeep'].contains(p.basename(file.path)),
    );

bool _sameBytes(File a, File b) {
  final aBytes = a.readAsBytesSync();
  final bBytes = b.readAsBytesSync();
  if (aBytes.length != bBytes.length) return false;
  for (var i = 0; i < aBytes.length; i++) {
    if (aBytes[i] != bBytes[i]) return false;
  }
  return true;
}
