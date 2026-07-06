import 'package:shadcn_flutter/shadcn_flutter.dart';

/// The re-seeded, cool near-black "instrument panel" color scheme.
///
/// Replaces shadcn's warm `darkStone` (whose `card` equalled `background`,
/// leaving the UI visually flat). This provides a genuine 4-step surface ramp
/// — background → card → popover → border — so panels, headers and floating
/// controls read as layered depth without raising overall brightness.
///
/// Domain and status colours live in `sidekick_colors.dart`; this file owns
/// only the neutral surfaces that shadcn components consume automatically.
const ColorScheme sidekickDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,

  // Surface ramp (darkest → lightest).
  background: Color(0xFF0A0C10),
  card: Color(0xFF12151C),
  popover: Color(0xFF171B24),
  muted: Color(0xFF1A1F28),
  secondary: Color(0xFF1A1F28),
  accent: Color(0xFF202632),
  input: Color(0xFF222933),
  border: Color(0xFF2A313D),

  // Foregrounds (cool near-white; muted meets ~7:1 on background).
  foreground: Color(0xFFE6E9EF),
  cardForeground: Color(0xFFE6E9EF),
  popoverForeground: Color(0xFFE6E9EF),
  secondaryForeground: Color(0xFFE6E9EF),
  accentForeground: Color(0xFFE6E9EF),
  mutedForeground: Color(0xFF97A0B0),

  // Primary action + focus ring.
  primary: Color(0xFFE6E9EF),
  primaryForeground: Color(0xFF0A0C10),
  ring: Color(0xFF3B82F6),

  // Destructive.
  destructive: Color(0xFFE05555),
  destructiveForeground: Color(0xFFFDECEC),

  // Charts (retained from darkStone; retuned in a later phase if needed).
  chart1: Color(0xFF2662D9),
  chart2: Color(0xFF2EB88A),
  chart3: Color(0xFFE88C30),
  chart4: Color(0xFFAF57DB),
  chart5: Color(0xFFE23670),
);
