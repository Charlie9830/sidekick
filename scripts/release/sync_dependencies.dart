/// Syncs every local sibling checkout listed under `dependencies:` in
/// `release_config.yaml` to its pinned ref.
///
/// See design_docs/production-build-spec.md section 6.2. Safe to run
/// standalone (`dart run scripts/release/sync_dependencies.dart`).
/// Refuses to touch a dirty working tree and leaves each checkout on a
/// detached HEAD at the pinned ref. A config with no dependencies is a
/// no-op.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'common.dart';

Future<void> main() => runScript(syncDependencies);

Future<void> syncDependencies() async {
  final config = loadReleaseConfig();
  final dependencies = loadDependencies(config);

  if (dependencies.isEmpty) {
    step('Syncing dependencies');
    stdout.writeln('No local dependencies to sync.');
    return;
  }

  for (final dependency in dependencies) {
    await _syncDependency(dependency);
  }
}

/// Clones (if needed) and checks out [dependency] at its pinned ref.
Future<void> _syncDependency(ReleaseDependency dependency) async {
  final name = dependency.name;
  final ref = dependency.ref;
  final checkoutPath = p.normalize(p.join(repoRoot, dependency.path));

  step('Syncing $name -> $ref');

  if (!Directory(checkoutPath).existsSync()) {
    stdout.writeln('$name checkout not found; cloning into $checkoutPath');
    await runChecked('git', ['clone', dependency.git, checkoutPath]);
  }

  await runChecked('git', ['-C', checkoutPath, 'fetch', '--tags', 'origin']);

  final dirty =
      await capture('git', ['-C', checkoutPath, 'status', '--porcelain']);
  if (dirty.isNotEmpty) {
    throw ReleaseException(
      'The $name checkout at $checkoutPath has uncommitted changes. '
      'Commit or stash them, then re-run. This script never discards '
      'local work.',
    );
  }

  // Resolve the pinned ref: a tag, or a commit SHA. Branch names are
  // rejected because they are not reproducible.
  var sha = await capture(
    'git',
    ['-C', checkoutPath, 'rev-parse', '--verify', '--quiet', 'refs/tags/$ref'],
    allowFailure: true,
  );
  if (sha.isEmpty) {
    if (!RegExp(r'^[0-9a-fA-F]{7,40}$').hasMatch(ref)) {
      throw ReleaseException(
        "$name ref '$ref' is neither a tag nor a commit SHA. Branch "
        'names are not allowed in release_config.yaml.',
      );
    }
    sha = await capture(
      'git',
      ['-C', checkoutPath, 'rev-parse', '--verify', '--quiet', '$ref^{commit}'],
      allowFailure: true,
    );
    if (sha.isEmpty) {
      throw ReleaseException(
        "$name ref '$ref' looks like a SHA but no such commit exists.",
      );
    }
  }

  await runChecked('git', ['-C', checkoutPath, 'checkout', '--detach', sha]);

  final depPubspec =
      File(p.join(checkoutPath, 'pubspec.yaml')).readAsStringSync();
  final depVersion = RegExp(r'^version:\s*(\S+)', multiLine: true)
          .firstMatch(depPubspec)
          ?.group(1) ??
      'unknown';

  stdout.writeln('$name synced: version $depVersion at $sha (detached HEAD)');
  stdout.writeln(
    'Note: the $name checkout is now on a detached HEAD; switch it back '
    'to a branch manually when returning to development.',
  );
}
