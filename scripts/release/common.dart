/// Shared helpers for the release scripts in `scripts/release/`.
///
/// Run entry points from the repo root with
/// `dart run scripts/release/<script>.dart` (requires `flutter pub get`
/// to have been run once beforehand).
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A fatal, user-facing release error. Reported without a stack trace.
class ReleaseException implements Exception {
  ReleaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Repo root, derived from this script's location (`scripts/release/..`).
final String repoRoot = p.normalize(
  p.join(p.dirname(Platform.script.toFilePath()), '..', '..'),
);

/// Runs [body], reporting a [ReleaseException] as a clean error message
/// and a non-zero exit code instead of a stack trace.
Future<void> runScript(Future<void> Function() body) async {
  try {
    await body();
  } on ReleaseException catch (error) {
    stderr.writeln('\nError: $error');
    exitCode = 1;
  }
}

void step(String message) {
  stdout.writeln('\n==> $message');
}

void warn(String message) {
  stdout.writeln('WARNING: $message');
}

/// Runs a command with live (inherited) output and throws on a non-zero
/// exit code.
///
/// [runInShell] is needed for `.bat` launchers (flutter, fastforge) but
/// must stay off otherwise: cmd.exe treats `^` as an escape character,
/// which corrupts arguments like git's `<sha>^{commit}`.
Future<void> runChecked(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool runInShell = false,
}) async {
  stdout.writeln('\$ $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory ?? repoRoot,
    mode: ProcessStartMode.inheritStdio,
    runInShell: runInShell,
  );
  final code = await process.exitCode;
  if (code != 0) {
    throw ReleaseException(
      "'$executable ${arguments.join(' ')}' failed with exit code $code.",
    );
  }
}

/// Runs a command and returns its trimmed stdout.
///
/// Throws on a non-zero exit code unless [allowFailure] is true, in
/// which case an empty string is returned instead.
Future<String> capture(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool allowFailure = false,
  bool runInShell = false,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory ?? repoRoot,
    runInShell: runInShell,
  );
  if (result.exitCode != 0) {
    if (allowFailure) return '';
    throw ReleaseException(
      "'$executable ${arguments.join(' ')}' failed with exit code "
      '${result.exitCode}.\n${result.stderr}',
    );
  }
  return (result.stdout as String).trim();
}

/// Whether a command runs successfully (exit code 0), discarding output.
Future<bool> succeeds(String executable, List<String> arguments) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: repoRoot,
    runInShell: false,
  );
  return result.exitCode == 0;
}

/// Loads `release_config.yaml` from the repo root.
YamlMap loadReleaseConfig() {
  final file = File(p.join(repoRoot, 'release_config.yaml'));
  if (!file.existsSync()) {
    throw ReleaseException('Release config not found at ${file.path}');
  }
  return loadYaml(file.readAsStringSync()) as YamlMap;
}

/// A local sibling package pinned by the release process.
///
/// Each entry under `dependencies:` in `release_config.yaml` describes a
/// git checkout that must exist beside this repo (so pubspec `path:`
/// references resolve) at a reproducible ref before a release build.
class ReleaseDependency {
  ReleaseDependency({
    required this.name,
    required this.git,
    required this.ref,
    required this.path,
  });

  /// The dependency's key in `release_config.yaml`, e.g. `mvr`.
  final String name;

  /// The git remote to clone from.
  final String git;

  /// A tag (preferred) or full commit SHA. Branch names are rejected.
  final String ref;

  /// Where the checkout must live, relative to this repo's root.
  final String path;
}

/// Reads every entry under `dependencies:` in [config].
///
/// Returns an empty list when the section is absent or empty, so apps
/// with no local dependencies need no special handling.
List<ReleaseDependency> loadDependencies(YamlMap config) {
  final section = config['dependencies'];
  if (section == null) return const [];
  if (section is! YamlMap) {
    throw ReleaseException(
      "release_config.yaml key 'dependencies' must be a mapping of named "
      'dependencies.',
    );
  }
  return [
    for (final key in section.keys)
      ReleaseDependency(
        name: key.toString(),
        git: configValue(config, 'dependencies.$key.git'),
        ref: configValue(config, 'dependencies.$key.ref'),
        path: configValue(config, 'dependencies.$key.path'),
      ),
  ];
}

/// Reads a required scalar from [config] by dotted key, e.g.
/// `dependencies.mvr.ref`.
String configValue(YamlMap config, String dottedKey) {
  dynamic node = config;
  for (final part in dottedKey.split('.')) {
    if (node is! YamlMap || !node.containsKey(part)) {
      throw ReleaseException(
        "release_config.yaml is missing required key '$dottedKey'.",
      );
    }
    node = node[part];
  }
  if (node == null || node is YamlMap) {
    throw ReleaseException(
      "release_config.yaml key '$dottedKey' is not a scalar value.",
    );
  }
  return node.toString();
}

/// Version and signing details read from the app's `pubspec.yaml`.
class PubspecInfo {
  PubspecInfo({
    required this.fullVersion,
    required this.buildName,
    required this.msixVersion,
    required this.certThumbprint,
  });

  /// e.g. `1.1.1+1`.
  final String fullVersion;

  /// e.g. `1.1.1`.
  final String buildName;

  /// e.g. `1.1.1.0`.
  final String msixVersion;

  /// The `/sha1` thumbprint from `msix_config.signtool_options`, if any.
  final String? certThumbprint;
}

PubspecInfo readPubspecInfo() {
  final content =
      File(p.join(repoRoot, 'pubspec.yaml')).readAsStringSync();
  final pubspec = loadYaml(content) as YamlMap;
  final version = pubspec['version']?.toString();
  if (version == null) {
    throw ReleaseException('pubspec.yaml: could not find version.');
  }
  final msixConfig = pubspec['msix_config'];
  final msixVersion =
      msixConfig is YamlMap ? msixConfig['msix_version']?.toString() : null;
  if (msixVersion == null) {
    throw ReleaseException(
      'pubspec.yaml: could not find msix_config.msix_version.',
    );
  }
  final signtoolOptions =
      msixConfig is YamlMap ? msixConfig['signtool_options']?.toString() : null;
  final thumbprint = signtoolOptions == null
      ? null
      : RegExp(r'/sha1\s+([0-9a-fA-F]{40})')
          .firstMatch(signtoolOptions)
          ?.group(1);
  return PubspecInfo(
    fullVersion: version,
    buildName: version.split('+').first,
    msixVersion: msixVersion,
    certThumbprint: thumbprint,
  );
}

/// Records the SHA-256 of [artifact] against [artifactName] in the
/// per-version [checksumsFile], replacing any prior line for the same
/// name so re-runs stay idempotent. Returns the checksum hex.
String recordChecksum(File checksumsFile, File artifact, String artifactName) {
  final sha256Hex = sha256.convert(artifact.readAsBytesSync()).toString();
  final otherLines = checksumsFile.existsSync()
      ? checksumsFile
            .readAsLinesSync()
            .where((line) => !line.endsWith('  $artifactName'))
            .toList()
      : <String>[];
  checksumsFile.writeAsStringSync(
    '${[...otherLines, '$sha256Hex  $artifactName'].join('\n')}\n',
  );
  return sha256Hex;
}

/// Copies [artifact] alongside itself under the version-free [stableName]
/// and returns the copy, for upload as the release asset.
///
/// A GitHub asset's `releases/latest/download/<name>` URL is derived from
/// the uploaded file's name, so a link that survives across releases needs
/// a filename that does too. The versioned original stays in `dist/`.
File stableUploadCopy(File artifact, String stableName) {
  final copy = File(p.join(artifact.parent.path, stableName));
  if (copy.existsSync()) copy.deleteSync();
  artifact.copySync(copy.path);
  return copy;
}

/// Builds this platform's block of the release notes (spec §8): date,
/// code-repo commit, pinned dependency refs and the checksums block.
///
/// The block is wrapped in HTML comment markers keyed by [platform] so
/// [publishRelease] can append it to — or replace it within — the notes
/// of a release the other platform (or an earlier run) already created.
String releaseNotesSection({
  required String platform,
  required String commit,
  required List<ReleaseDependency> dependencies,
  required File checksumsFile,
  required String date,
}) {
  final dependencyNotes = [
    for (final dependency in dependencies)
      '- ${dependency.name} ref: `${dependency.ref}`',
  ].join('\n');
  return '''
${_sectionStart(platform)}
## $platform

- Date: $date
- Source commit: `$commit`${dependencyNotes.isEmpty ? '' : '\n$dependencyNotes'}

### Checksums (SHA-256)

```
${checksumsFile.readAsStringSync().trim()}
```
${_sectionEnd(platform)}''';
}

String _sectionStart(String platform) => '<!-- release:$platform -->';

String _sectionEnd(String platform) => '<!-- /release:$platform -->';

/// Returns [body] with [platform]'s section replaced by [section], or
/// with [section] appended when the body has no such section yet.
String mergeNotesSection(String body, String platform, String section) {
  final start = body.indexOf(_sectionStart(platform));
  final end = body.indexOf(_sectionEnd(platform));
  if (start != -1 && end > start) {
    final tail = end + _sectionEnd(platform).length;
    return '${body.substring(0, start)}$section${body.substring(tail)}';
  }
  return '${body.trimRight()}\n\n$section\n';
}

/// An existing GitHub release, published or draft.
class GithubRelease {
  GithubRelease({required this.isDraft, required this.body, required this.url});

  final bool isDraft;
  final String body;
  final String url;
}

/// Finds the release tagged [tag] in [githubRepo], or null if there is
/// none.
///
/// Lists releases rather than asking for the tag directly: a draft
/// release has no git tag behind it, so the `releases/tags/{tag}`
/// endpoint 404s for one and only a listing reliably sees it.
Future<GithubRelease?> findRelease({
  required String tag,
  required String githubRepo,
}) async {
  final output = await capture('gh', [
    'api',
    'repos/$githubRepo/releases',
    '--paginate',
    '--jq',
    'map(select(.tag_name == "$tag")) | first // empty',
  ]);
  // `--paginate` applies the filter per page, so take the first page
  // that matched.
  final match = const LineSplitter()
      .convert(output)
      .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
  if (match.isEmpty) return null;
  final release = jsonDecode(match) as Map<String, dynamic>;
  return GithubRelease(
    isDraft: release['draft'] == true,
    body: (release['body'] as String?) ?? '',
    url: (release['html_url'] as String?) ?? '',
  );
}

/// Creates the `v<version>` GitHub release in [githubRepo] with
/// [assets], or adds to it when it already exists, then returns its URL.
///
/// Mirrors spec §8: a release created by whichever platform publishes
/// first is reused by the second, including while it is still a draft.
/// Re-publishing an existing release uploads this platform's assets and
/// merges [notesSection] into the notes under the [platform] marker, so
/// repeated runs converge rather than fail.
///
/// Assets are replaced automatically on a draft, which is by definition
/// not yet released to anyone. Overwriting an asset on an already
/// published release needs [force], so a shipped download is never
/// swapped out by accident.
Future<String> publishRelease({
  required String tag,
  required String githubRepo,
  required String title,
  required String platform,
  required String notesSection,
  required bool draft,
  required bool force,
  required List<File> assets,
}) async {
  final assetPaths = [for (final asset in assets) asset.path];
  final existing = await findRelease(tag: tag, githubRepo: githubRepo);

  if (existing == null) {
    final notesFile = File(
      p.join(Directory.systemTemp.path, 'release-notes-$tag.md'),
    )..writeAsStringSync('# $title\n\n$notesSection\n');
    await runChecked('gh', [
      'release',
      'create',
      tag,
      '--repo',
      githubRepo,
      '--title',
      title,
      '--notes-file',
      notesFile.path,
      if (draft) '--draft',
      ...assetPaths,
    ]);
    return _releaseUrl(tag: tag, githubRepo: githubRepo);
  }

  final state = existing.isDraft ? 'draft release' : 'release';
  stdout.writeln('$state $tag already exists; adding to it.');
  final clobber = force || existing.isDraft;
  if (!clobber) {
    warn(
      'Uploading into published release $tag. Assets already attached '
      'there will not be replaced; re-run with --force to overwrite '
      'them.',
    );
  }
  await runChecked('gh', [
    'release',
    'upload',
    tag,
    '--repo',
    githubRepo,
    ...assetPaths,
    if (clobber) '--clobber',
  ]);

  final mergedNotes = File(
    p.join(Directory.systemTemp.path, 'release-notes-$tag.md'),
  )..writeAsStringSync(
    mergeNotesSection(existing.body, platform, notesSection),
  );
  await runChecked('gh', [
    'release',
    'edit',
    tag,
    '--repo',
    githubRepo,
    '--notes-file',
    mergedNotes.path,
  ]);
  return _releaseUrl(tag: tag, githubRepo: githubRepo);
}

Future<String> _releaseUrl({
  required String tag,
  required String githubRepo,
}) => capture('gh', [
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
