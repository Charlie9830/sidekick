/// Syncs the mvr sibling checkout to the ref pinned in
/// `release_config.yaml`.
///
/// See design_docs/production-build-spec.md section 6.2. Safe to run
/// standalone (`dart run scripts/release/sync_dependencies.dart`).
/// Refuses to touch a dirty mvr working tree and leaves the checkout on
/// a detached HEAD at the pinned ref.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'common.dart';

Future<void> main() => runScript(syncDependencies);

Future<void> syncDependencies() async {
  final config = loadReleaseConfig();
  final gitUrl = configValue(config, 'dependencies.mvr.git');
  final ref = configValue(config, 'dependencies.mvr.ref');
  final relPath = configValue(config, 'dependencies.mvr.path');
  final mvrPath = p.normalize(p.join(repoRoot, relPath));

  step('Syncing mvr -> $ref');

  if (!Directory(mvrPath).existsSync()) {
    stdout.writeln('mvr checkout not found; cloning into $mvrPath');
    await runChecked('git', ['clone', gitUrl, mvrPath]);
  }

  await runChecked('git', ['-C', mvrPath, 'fetch', '--tags', 'origin']);

  final dirty = await capture('git', ['-C', mvrPath, 'status', '--porcelain']);
  if (dirty.isNotEmpty) {
    throw ReleaseException(
      'The mvr checkout at $mvrPath has uncommitted changes. Commit or '
      'stash them, then re-run. This script never discards local work.',
    );
  }

  // Resolve the pinned ref: a tag, or a commit SHA. Branch names are
  // rejected because they are not reproducible.
  var sha = await capture(
    'git',
    ['-C', mvrPath, 'rev-parse', '--verify', '--quiet', 'refs/tags/$ref'],
    allowFailure: true,
  );
  if (sha.isEmpty) {
    if (!RegExp(r'^[0-9a-fA-F]{7,40}$').hasMatch(ref)) {
      throw ReleaseException(
        "mvr ref '$ref' is neither a tag nor a commit SHA. Branch names "
        'are not allowed in release_config.yaml.',
      );
    }
    sha = await capture(
      'git',
      ['-C', mvrPath, 'rev-parse', '--verify', '--quiet', '$ref^{commit}'],
      allowFailure: true,
    );
    if (sha.isEmpty) {
      throw ReleaseException(
        "mvr ref '$ref' looks like a SHA but no such commit exists.",
      );
    }
  }

  await runChecked('git', ['-C', mvrPath, 'checkout', '--detach', sha]);

  final mvrPubspec =
      File(p.join(mvrPath, 'pubspec.yaml')).readAsStringSync();
  final mvrVersion = RegExp(r'^version:\s*(\S+)', multiLine: true)
          .firstMatch(mvrPubspec)
          ?.group(1) ??
      'unknown';

  stdout.writeln('mvr synced: version $mvrVersion at $sha (detached HEAD)');
  stdout.writeln(
    'Note: the mvr checkout is now on a detached HEAD; switch it back '
    'to a branch manually when returning to development.',
  );
}
