/// Builds, signs, notarizes and publishes the macOS PKG production
/// release.
///
/// See design_docs/production-build-spec.md section 7. Run from the repo
/// root on a Mac: `dart run scripts/release/build_macos.dart [flags]`
///
/// Flags:
/// - `--dry-run`       run everything except the publish step.
/// - `--skip-publish`  build only; leave artifacts in dist/.
/// - `--force`         allow overwriting an already-uploaded asset on an
///                     existing GitHub release (gh --clobber).
/// - `--allow-dirty`   skip the clean-working-tree preflight check. For
///                     testing the pipeline only - never for a release.
///
/// Signing and notarization are done with explicit `codesign`,
/// `productbuild`, `notarytool` and `stapler` steps rather than through
/// Fastforge: the .app must be signed with the hardened runtime *before*
/// the .pkg is built, and the explicit path gives that ordering cleanly
/// (spec §7.3 permits this — "explicit steps are acceptable and easier to
/// debug").
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'apply_patches.dart';
import 'common.dart';
import 'sync_dependencies.dart';

Future<void> main(List<String> args) => runScript(() => buildMacos(args));

Future<void> buildMacos(List<String> args) async {
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

  if (!Platform.isMacOS) {
    throw ReleaseException('This script must run on a macOS machine.');
  }

  // -------------------------------------------------------------- preflight

  step('Preflight');

  final flutterVersion = (await capture('flutter', [
    '--version',
  ])).split('\n').first.trim();
  stdout.writeln(flutterVersion);

  final treeStatus = await capture('git', ['status', '--porcelain']);
  if (treeStatus.isNotEmpty) {
    if (allowDirty) {
      warn(
        'Working tree is dirty (--allow-dirty given). NOT a release build.',
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
  final applicationIdentity =
      configValue(config, 'macos.application_identity');
  final installerIdentity = configValue(config, 'macos.installer_identity');
  final notaryProfile = configValue(config, 'macos.notary_profile');

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
  stdout.writeln('Releasing version $version');

  // Signing identities must exist in a keychain. `security find-identity`
  // lists both Developer ID Application and Installer certs.
  final identities = await capture('security', ['find-identity', '-v']);
  for (final identity in [applicationIdentity, installerIdentity]) {
    if (!identities.contains(identity)) {
      throw ReleaseException(
        "Signing identity '$identity' was not found in the keychain "
        '(`security find-identity -v`). Import the Developer ID '
        'certificate before releasing.',
      );
    }
    stdout.writeln('Signing identity present: $identity');
  }

  // notarytool credential profile must exist. `history` is a cheap call
  // that authenticates against the stored profile.
  final notaryOk = await succeeds('xcrun', [
    'notarytool',
    'history',
    '--keychain-profile',
    notaryProfile,
  ]);
  if (!notaryOk) {
    throw ReleaseException(
      "notarytool profile '$notaryProfile' is missing or invalid. Create "
      'it once with `xcrun notarytool store-credentials $notaryProfile` '
      '(needs your Apple ID and an app-specific password).',
    );
  }
  stdout.writeln('notarytool profile present: $notaryProfile');

  if (publishing) {
    await runChecked('gh', ['auth', 'status']);
    await capture('gh', ['repo', 'view', githubRepo, '--json', 'name']);
    stdout.writeln('GitHub target repo reachable: $githubRepo');
  }

  // ----------------------------------------------------------- dependencies

  await syncDependencies();

  // ------------------------------------------------------------------ build

  step('flutter clean + pub get');
  await runChecked('flutter', ['clean']);
  await runChecked('flutter', ['pub', 'get']);

  applyPatches('macos');

  // These two guards run *after* patching, not in preflight: the patch
  // tree is what restores the files, so checking beforehand would fail a
  // build that the patch step was about to fix. What they catch now is a
  // patch tree that has itself lost the content (spec §7.0).
  step('Verifying patched sources');

  final appDelegate = File(
    p.join(repoRoot, 'macos', 'Runner', 'AppDelegate.swift'),
  );
  if (!appDelegate.existsSync() ||
      !RegExp(
        r'func\s+applicationShouldTerminate\s*\(',
      ).hasMatch(appDelegate.readAsStringSync())) {
    throw ReleaseException(
      'AppDelegate.swift is missing the applicationShouldTerminate '
      'override, which would silently break the unsaved-changes prompt on '
      '⌘Q. Restore the window_manager Quit override in '
      'patches/macos/macos/Runner/AppDelegate.swift (see '
      'window-management-spec.md §4b) before releasing.',
    );
  }
  stdout.writeln('AppDelegate Quit override present.');

  // Hardened runtime is applied at codesign time; here we only confirm
  // the entitlements file the signing step relies on exists (spec §7.1.5).
  final entitlements = File(
    p.join(repoRoot, 'macos', 'Runner', 'Release.entitlements'),
  );
  if (!entitlements.existsSync()) {
    throw ReleaseException(
      'Missing ${entitlements.path}. Expected patches/macos/macos/Runner/'
      'Release.entitlements to provide it.',
    );
  }
  stdout.writeln('Entitlements present: ${p.basename(entitlements.path)}');

  step('flutter test (release gate)');
  await runChecked('flutter', ['test']);

  // A release build produces a universal (arm64 + x86_64) binary by
  // default, per the Xcode project's ARCHS setting.
  step('flutter build macos (release)');
  await runChecked('flutter', ['build', 'macos', '--release']);

  final appBundle = _renameAppBundle(_locateAppBundle(), displayName);
  stdout.writeln('Built ${p.basename(appBundle.path)}');

  // ---------------------------------------------------------- sign the .app

  step('Signing app bundle (Developer ID Application, hardened runtime)');
  await _signAppBundle(appBundle, applicationIdentity, entitlements);
  await runChecked('codesign', [
    '--verify',
    '--deep',
    '--strict',
    '--verbose=2',
    appBundle.path,
  ]);

  // ---------------------------------------------------------- build the .pkg

  step('Building signed installer (productbuild, Developer ID Installer)');
  final distDir = Directory(p.join(repoRoot, 'dist'))..createSync();
  final artifactName = '$artifactSlug-macos-universal.pkg';
  final pkg = File(p.join(distDir.path, artifactName));
  if (pkg.existsSync()) pkg.deleteSync();
  await runChecked('productbuild', [
    '--component',
    appBundle.path,
    '/Applications',
    '--sign',
    installerIdentity,
    '--timestamp',
    pkg.path,
  ]);

  // ----------------------------------------------------------- notarization

  step('Notarizing (xcrun notarytool submit --wait)');
  await _notarize(pkg, notaryProfile);

  step('Stapling notarization ticket');
  await runChecked('xcrun', ['stapler', 'staple', pkg.path]);

  step('Gatekeeper assessment (spctl)');
  await runChecked('spctl', [
    '--assess',
    '--type',
    'install',
    '-vv',
    pkg.path,
  ]);

  // -------------------------------------------------------------- artifacts

  step('Recording checksum');
  final checksumsFile = File(p.join(distDir.path, 'checksums-$version.txt'));
  final sha256Hex = recordChecksum(checksumsFile, pkg, artifactName);
  stdout.writeln('SHA-256: $sha256Hex');

  // ---------------------------------------------------------------- publish

  if (!publishing) {
    step('Publish skipped');
    stdout.writeln('Artifact ready: ${pkg.path}');
    return;
  }

  step('Publishing to $githubRepo');
  final tag = 'v$version';
  final date = DateTime.now().toIso8601String().split('T').first;
  final notesFile = writeReleaseNotes(
    tag: tag,
    displayName: displayName,
    commit: commit,
    dependencies: loadDependencies(config),
    checksumsFile: checksumsFile,
    date: date,
  );
  final releaseUrl = await publishRelease(
    tag: tag,
    githubRepo: githubRepo,
    title: '$displayName $tag',
    notesFile: notesFile,
    draft: draft,
    force: force,
    assets: [pkg, checksumsFile],
  );

  step('Done');
  stdout.writeln('Release: $releaseUrl');
  stdout.writeln('Artifact: $artifactName ($sha256Hex)');
}

/// The single `.app` produced under the release products directory.
File _locateAppBundle() {
  final productsDir = Directory(
    p.join(repoRoot, 'build', 'macos', 'Build', 'Products', 'Release'),
  );
  if (!productsDir.existsSync()) {
    throw ReleaseException(
      'No release products at ${productsDir.path}. Did the build fail?',
    );
  }
  final apps = productsDir
      .listSync()
      .whereType<Directory>()
      .where((entry) => entry.path.endsWith('.app'))
      .toList();
  if (apps.isEmpty) {
    throw ReleaseException('No .app bundle found in ${productsDir.path}.');
  }
  if (apps.length > 1) {
    throw ReleaseException(
      'Expected exactly one .app in ${productsDir.path}, found '
      '${apps.length}: ${apps.map((a) => p.basename(a.path)).join(', ')}.',
    );
  }
  return File(apps.single.path);
}

/// Renames [appBundle] to `<display_name>.app` so the installed
/// application, not just the release title, carries the product name.
///
/// Flutter names the bundle after the Xcode `PRODUCT_NAME` (the Dart
/// package name), which is an internal detail. Renaming here rather than
/// in the Xcode project keeps debug builds untouched and keeps
/// `release_config.yaml` the single source of the product name. The
/// rename happens before signing so the signature is applied to the
/// bundle as it ships; the executable inside `Contents/MacOS` keeps its
/// own name, which `CFBundleExecutable` still points at.
File _renameAppBundle(File appBundle, String displayName) {
  // `/` and `:` are the two characters HFS+/APFS and Finder disallow in a
  // file name; everything else in a display name is safe.
  final safeName = displayName.replaceAll(RegExp(r'[/:]'), '-');
  final target = p.join(p.dirname(appBundle.path), '$safeName.app');
  if (target == appBundle.path) return appBundle;
  final existing = Directory(target);
  if (existing.existsSync()) existing.deleteSync(recursive: true);
  Directory(appBundle.path).renameSync(target);
  return File(target);
}

/// Signs nested frameworks/dylibs first, then the app bundle, all with
/// the hardened runtime and a secure timestamp.
///
/// Apple recommends signing inside-out over `codesign --deep`; only the
/// outer bundle carries the app entitlements.
Future<void> _signAppBundle(
  File appBundle,
  String identity,
  File entitlements,
) async {
  final frameworksDir = Directory(
    p.join(appBundle.path, 'Contents', 'Frameworks'),
  );
  if (frameworksDir.existsSync()) {
    final nested = frameworksDir
        .listSync()
        .where(
          (entry) =>
              entry.path.endsWith('.framework') ||
              entry.path.endsWith('.dylib'),
        )
        .toList();
    for (final item in nested) {
      await runChecked('codesign', [
        '--force',
        '--timestamp',
        '--options',
        'runtime',
        '--sign',
        identity,
        item.path,
      ]);
    }
  }
  await runChecked('codesign', [
    '--force',
    '--timestamp',
    '--options',
    'runtime',
    '--entitlements',
    entitlements.path,
    '--sign',
    identity,
    appBundle.path,
  ]);
}

/// Submits [pkg] to notarytool, waits, and fails the build with the log
/// URL/output if Apple does not accept it.
Future<void> _notarize(File pkg, String profile) async {
  final output = await capture('xcrun', [
    'notarytool',
    'submit',
    pkg.path,
    '--keychain-profile',
    profile,
    '--wait',
    '--output-format',
    'json',
  ]);
  final jsonStart = output.indexOf('{');
  Map<String, dynamic> result;
  try {
    result =
        jsonDecode(output.substring(jsonStart)) as Map<String, dynamic>;
  } on Object {
    throw ReleaseException('Could not parse notarytool output:\n$output');
  }
  final status = result['status'];
  final id = result['id'];
  stdout.writeln('Notarization $id: $status');
  if (status != 'Accepted') {
    if (id is String) {
      final log = await capture('xcrun', [
        'notarytool',
        'log',
        id,
        '--keychain-profile',
        profile,
      ], allowFailure: true);
      if (log.isNotEmpty) stdout.writeln(log);
    }
    throw ReleaseException(
      "Notarization failed with status '$status'. See the log above.",
    );
  }
}
