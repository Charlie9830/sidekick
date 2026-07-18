/// Shared helpers for the release scripts in `scripts/release/`.
///
/// Run entry points from the repo root with
/// `dart run scripts/release/<script>.dart` (requires `flutter pub get`
/// to have been run once beforehand).
library;

import 'dart:io';

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
