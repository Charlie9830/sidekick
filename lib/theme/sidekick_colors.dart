import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Central design tokens for Sidekick's dark, high-density UI.
///
/// These are the single source of truth for domain colours (power, data,
/// control), status flags, interaction states and grid lines. Prefer these
/// over raw `Colors.*` literals so meaning stays consistent across every
/// screen and can be retuned in one place.
///
/// Base surfaces (background, card, border, foreground, mutedForeground) live
/// on the [ColorScheme] in `sidekick_color_scheme.dart` and should be read via
/// `Theme.of(context).colorScheme`.
///
/// Colours are tuned for the cool near-black surface ramp: text tokens meet
/// WCAG 4.5:1 and line/mark tokens meet 3:1 against [background].
abstract final class SidekickColors {
  // --- Power (red family) — brightness encodes run importance -------------
  /// Link cable between adjacent fixtures.
  static const Color powerLink = Color(0xFFF2A6A6);

  /// Run from a header to a fixture.
  static const Color powerRun = Color(0xFFE05C5C);

  /// Home run back to the distro/rack (drawn heaviest).
  static const Color powerHome = Color(0xFFC23A3A);

  // --- Data (blue family) -------------------------------------------------
  static const Color dataLink = Color(0xFF93B9F2);
  static const Color dataRun = Color(0xFF4C86E0);
  static const Color dataHome = Color(0xFF2C5BB8);

  /// Control/data-multi accent (teal).
  static const Color control = Color(0xFF2FA79E);

  // --- Electrical phases (L1 / L2 / L3) ----------------------------------
  /// Phase 1 marker/text (red family).
  static const Color phase1 = Color(0xFFE05C5C);

  /// Phase 2 marker/text (neutral light steel; the "white" phase).
  static const Color phase2 = Color(0xFFB8C0CC);

  /// Phase 3 marker/text (blue family).
  static const Color phase3 = Color(0xFF4C86E0);

  // --- Graph node / marker accents ---------------------------------------
  /// Physical location marker (amber; replaces raw yellow).
  static const Color locationMarker = Color(0xFFE0B341);
  static const Color powerMultiNode = powerRun;
  static const Color dataMultiNode = control;

  // --- Status flags -------------------------------------------------------
  static const Color spare = Color(0xFFD65C9A);
  static const Color dropper = Color(0xFF4FAE6E);
  static const Color extension = dataRun;

  // --- Semantic states ----------------------------------------------------
  static const Color warning = Color(0xFFE0A030);
  static const Color error = Color(0xFFE05555);
  static const Color success = Color(0xFF4FAE6E);

  // --- Diff states --------------------------------------------------------
  /// Newly added item in a diff.
  static const Color diffAdded = success;

  /// Modified item in a diff.
  static const Color diffChanged = warning;

  /// Removed item in a diff.
  static const Color diffDeleted = error;

  // --- Flag / classification accents -------------------------------------
  /// Motor / rigging cable classification.
  static const Color motor = Color(0xFF9B6BD6);

  /// Hoist / rigging outlet marker.
  static const Color hoist = Color(0xFF56B6C2);

  /// Neutral, low-emphasis flag (e.g. "Permanent"): a muted steel chip.
  static const Color neutralFlag = Color(0xFF3A4250);

  /// Emphasis flag reusing the data-run blue (e.g. "Custom").
  static const Color infoFlag = dataRun;

  // --- Lines & interaction ------------------------------------------------
  /// Interior table grid lines — subtler than [ColorScheme.border].
  static const Color gridLine = Color(0xFF1E232C);

  /// Row hover fill.
  static const Color rowHover = Color(0xFF171B24);

  /// Selected row fill (azure-tinted, distinct from any domain colour).
  static const Color rowSelected = Color(0xFF1B2C46);

  /// Range-selected row fill (green-tinted; replaces raw `Colors.green[900]`).
  static const Color rowRangeSelected = Color(0xFF163020);

  /// Accent reserved for selection / active / focus rings.
  static const Color selectionAccent = Color(0xFF3B82F6);
}

/// Layout density tokens for tables and dense lists.
abstract final class SidekickDensity {
  /// Compact grid row (cable rows, outlet rows).
  static const double rowCompact = 26.0;

  /// Standard grid row (fixture table, patch rows).
  static const double rowStandard = 40.0;

  /// Horizontal padding inside a table cell / row.
  static const double cellPaddingH = 16.0;

  /// Default gap between inline row elements.
  static const double gap = 8.0;

  static const double indent = 16;
}
