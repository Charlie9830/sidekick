/// Builds, verifies and publishes the Windows MSIX production release.
///
/// See design_docs/production-build-spec.md section 6. Run from the repo
/// root: `dart run scripts/release/build_windows.dart [flags]`
///
/// Flags:
/// - `--dry-run`       run everything except the publish step.
/// - `--skip-publish`  build only; leave artifacts in dist/.
/// - `--force`         allow overwriting an already-uploaded asset on an
///                     existing GitHub release (gh --clobber).
/// - `--allow-dirty`   skip the clean-working-tree preflight check. For
///                     testing the pipeline only - never for a release.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'apply_patches.dart';
import 'common.dart';
import 'sync_dependencies.dart';

Future<void> main(List<String> args) => runScript(() => buildWindows(args));

Future<void> buildWindows(List<String> args) async {
  const flags = ['--dry-run', '--skip-publish', '--force', '--allow-dirty'];
  final unknown = args.where((arg) => !flags.contains(arg)).toList();
  if (unknown.isNotEmpty) {
    throw ReleaseException(
      'Unknown argument(s): ${unknown.join(', ')}. '
      'Valid flags: ${flags.join(', ')}',
    );
  }
  final dryRun = args.contains('--dry-run');
  final skipPublish = args.contains('--skip-publish');
  final force = args.contains('--force');
  final allowDirty = args.contains('--allow-dirty');
  final publishing = !(dryRun || skipPublish);

  if (!Platform.isWindows) {
    throw ReleaseException('This script must run on a Windows machine.');
  }

  // -------------------------------------------------------------- preflight

  step('Preflight');

  final flutterVersion = (await capture('flutter', [
    '--version',
  ], runInShell: true)).split('\n').first.trim();
  stdout.writeln(flutterVersion);

  final treeStatus = await capture('git', ['status', '--porcelain']);
  if (treeStatus.isNotEmpty) {
    if (allowDirty) {
      warn(
        'Working tree is dirty (--allow-dirty given). NOT a release '
        'build.',
      );
    } else {
      throw ReleaseException(
        'The working tree has uncommitted changes. Release builds must '
        'run from a clean tree.',
      );
    }
  }
  final branch = await capture('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  final commit = await capture('git', ['rev-parse', 'HEAD']);
  if (branch != 'master') {
    warn("Releasing from branch '$branch', not master.");
  }
  stdout.writeln('Code repo at $commit ($branch)');

  final config = loadReleaseConfig();
  final githubRepo = configValue(config, 'publish.github.repo');
  final displayName = configValue(config, 'app.display_name');
  final artifactSlug = configValue(config, 'app.artifact_slug');
  final draft = configValue(config, 'publish.github.draft') == 'true';

  final pubspec = readPubspecInfo();
  final version = pubspec.buildName;
  final expectedMsix = '$version.0';
  if (pubspec.msixVersion != expectedMsix) {
    throw ReleaseException(
      'Version mismatch: pubspec version is ${pubspec.fullVersion} but '
      'msix_version is ${pubspec.msixVersion}; expected $expectedMsix. '
      'Update pubspec.yaml so they agree.',
    );
  }
  stdout.writeln('Releasing version $version (msix ${pubspec.msixVersion})');

  final thumbprint = pubspec.certThumbprint;
  if (thumbprint == null) {
    throw ReleaseException(
      'Could not find a /sha1 thumbprint in msix_config.signtool_options.',
    );
  }
  final certSubject = await capture('powershell', [
    '-NoProfile',
    '-Command',
    r'Get-ChildItem Cert:\CurrentUser\My, Cert:\LocalMachine\My '
        "-ErrorAction SilentlyContinue | Where-Object Thumbprint -eq "
        "'$thumbprint' | Select-Object -First 1 -ExpandProperty Subject",
  ]);
  if (certSubject.isEmpty) {
    throw ReleaseException(
      'Signing certificate $thumbprint was not found in the CurrentUser '
      'or LocalMachine certificate store.',
    );
  }
  stdout.writeln('Signing certificate present: $certSubject');

  if (publishing) {
    await runChecked('gh', ['auth', 'status']);
    await capture('gh', ['repo', 'view', githubRepo, '--json', 'name']);
    stdout.writeln('GitHub target repo reachable: $githubRepo');
  }

  // ----------------------------------------------------------- dependencies

  await syncDependencies();

  // ------------------------------------------------------------------ build

  step('flutter clean + pub get');
  await runChecked('flutter', ['clean'], runInShell: true);
  await runChecked('flutter', ['pub', 'get'], runInShell: true);

  applyPatches('windows');

  step('flutter test (release gate)');
  await runChecked('flutter', ['test'], runInShell: true);

  step('fastforge package (windows/msix)');
  final fastforge = await _resolveFastforge();
  await runChecked(fastforge, [
    'package',
    '--platform',
    'windows',
    '--targets',
    'msix',
  ], runInShell: true);

  // -------------------------------------------------------------- artifacts

  step('Verifying artifact');

  final distDir = Directory(p.join(repoRoot, 'dist'));
  final artifactName = '$artifactSlug-windows-x64.msix';
  final built = _newestBuiltMsix(distDir, exclude: artifactName);
  final artifact = File(p.join(distDir.path, artifactName));
  built.copySync(artifact.path);

  final signature = await capture('powershell', [
    '-NoProfile',
    '-Command',
    "\$s = Get-AuthenticodeSignature '${artifact.path}'; "
        'Write-Output "\$(\$s.Status)|\$(\$s.SignerCertificate.Subject)"',
  ]);
  final signatureParts = signature.split('|');
  if (signatureParts.first != 'Valid') {
    throw ReleaseException('MSIX signature check failed: $signature');
  }
  stdout.writeln('Signature valid: ${signatureParts.last}');

  final sha256Hex = sha256.convert(artifact.readAsBytesSync()).toString();
  final checksumsFile = File(p.join(distDir.path, 'checksums-$version.txt'));
  final otherLines = checksumsFile.existsSync()
      ? checksumsFile
            .readAsLinesSync()
            .where((line) => !line.endsWith('  $artifactName'))
            .toList()
      : <String>[];
  checksumsFile.writeAsStringSync(
    '${[...otherLines, '$sha256Hex  $artifactName'].join('\n')}\n',
  );
  stdout.writeln('SHA-256: $sha256Hex');

  // ---------------------------------------------------------------- publish

  if (!publishing) {
    step('Publish skipped');
    stdout.writeln('Artifact ready: ${artifact.path}');
    return;
  }

  step('Publishing to $githubRepo');

  final tag = 'v$version';
  final dependencyNotes = [
    for (final dependency in loadDependencies(config))
      '- ${dependency.name} ref: `${dependency.ref}`',
  ].join('\n');
  final date = DateTime.now().toIso8601String().split('T').first;
  final notesFile = File(
    p.join(Directory.systemTemp.path, 'release-notes-$tag.md'),
  );
  notesFile.writeAsStringSync('''
# $displayName $tag

- Date: $date
- Source commit: `$commit`${dependencyNotes.isEmpty ? '' : '\n$dependencyNotes'}

## Checksums (SHA-256)

```
${checksumsFile.readAsStringSync().trim()}
```
''');

  final releaseExists = await succeeds('gh', [
    'release',
    'view',
    tag,
    '--repo',
    githubRepo,
  ]);
  if (releaseExists) {
    stdout.writeln('Release $tag exists; uploading assets.');
    await runChecked('gh', [
      'release',
      'upload',
      tag,
      '--repo',
      githubRepo,
      artifact.path,
      checksumsFile.path,
      if (force) '--clobber',
    ]);
  } else {
    await runChecked('gh', [
      'release',
      'create',
      tag,
      '--repo',
      githubRepo,
      '--title',
      '$displayName $tag',
      '--notes-file',
      notesFile.path,
      if (draft) '--draft',
      artifact.path,
      checksumsFile.path,
    ]);
  }

  final releaseUrl = await capture('gh', [
    'release',
    'view',
    tag,
    '--repo',
    githubRepo,
    '--json',
    'url',
    '--jq',
    '.url',
  ]);
  step('Done');
  stdout.writeln('Release: $releaseUrl');
  stdout.writeln('Artifact: $artifactName ($sha256Hex)');
}

/// Locates fastforge on PATH, falling back to the pub global bin
/// directory.
Future<String> _resolveFastforge() async {
  final onPath = await capture('where', ['fastforge'], allowFailure: true);
  if (onPath.isNotEmpty) return onPath.split('\n').first.trim();
  final localAppData = Platform.environment['LOCALAPPDATA'];
  if (localAppData != null) {
    final pubBin = p.join(localAppData, 'Pub', 'Cache', 'bin', 'fastforge.bat');
    if (File(pubBin).existsSync()) return pubBin;
  }
  throw ReleaseException(
    'fastforge not found. Install it with: dart pub global activate '
    'fastforge',
  );
}

/// The most recently modified fastforge-built .msix under [distDir],
/// ignoring our own normalized artifact name.
File _newestBuiltMsix(Directory distDir, {required String exclude}) {
  if (!distDir.existsSync()) {
    throw ReleaseException('No dist directory at ${distDir.path}.');
  }
  final candidates =
      distDir
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.msix') && p.basename(file.path) != exclude,
          )
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  if (candidates.isEmpty) {
    throw ReleaseException('No .msix produced under ${distDir.path}.');
  }
  return candidates.first;
}
