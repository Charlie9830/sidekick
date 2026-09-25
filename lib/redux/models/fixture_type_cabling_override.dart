import 'package:sidekick/redux/models/cable_model.dart';

/// How to cable a chain of fixtures whose connectors run against the order
/// they are patched in, e.g. bars with their input at the far end from the
/// header.
enum ChainOrientation {
  /// Run the fixture home run to the furthest fixture, then link back toward
  /// the header with short links.
  homeRunToFurthest('Home run to furthest'),

  /// Keep the home run to the nearest fixture and use longer links that fold
  /// back to each next fixture's input.
  foldBackLinks('Fold-back links');

  final String label;

  const ChainOrientation(this.label);
}

/// A location's breakout cabling overrides for one fixture type.
///
/// A null cable leaves that signal's connectors as the fixture type's GDTF
/// wiring describes them.
class FixtureTypeCablingOverride {
  /// The cable used for both power connectors, e.g. AU10A in place of True1.
  final CableType? power;

  /// The cable used for both data connectors.
  final CableType? data;

  /// How chains led by this fixture type are cabled when they run against
  /// the flow.
  final ChainOrientation orientation;

  const FixtureTypeCablingOverride({
    this.power,
    this.data,
    this.orientation = ChainOrientation.homeRunToFurthest,
  });

  const FixtureTypeCablingOverride.none()
    : power = null,
      data = null,
      orientation = ChainOrientation.homeRunToFurthest;

  bool get isEmpty =>
      power == null &&
      data == null &&
      orientation == ChainOrientation.homeRunToFurthest;

  /// This override with its power cable set to [power] (null clears it).
  FixtureTypeCablingOverride withPower(CableType? power) =>
      FixtureTypeCablingOverride(
        power: power,
        data: data,
        orientation: orientation,
      );

  /// This override with its data cable set to [data] (null clears it).
  FixtureTypeCablingOverride withData(CableType? data) =>
      FixtureTypeCablingOverride(
        power: power,
        data: data,
        orientation: orientation,
      );

  /// This override with its chain orientation set to [orientation].
  FixtureTypeCablingOverride withOrientation(ChainOrientation orientation) =>
      FixtureTypeCablingOverride(
        power: power,
        data: data,
        orientation: orientation,
      );

  Map<String, dynamic> toMap() => {
    'power': power?.name,
    'data': data?.name,
    'orientation': orientation.name,
  };

  factory FixtureTypeCablingOverride.fromMap(Map<String, dynamic> map) =>
      FixtureTypeCablingOverride(
        power: _cableTypeByName(map['power']),
        data: _cableTypeByName(map['data']),
        orientation:
            ChainOrientation.values.asNameMap()[map['orientation']] ??
            ChainOrientation.homeRunToFurthest,
      );

  /// Parses a stored cable name, ignoring names this build doesn't know.
  static CableType? _cableTypeByName(Object? name) =>
      CableType.values.asNameMap()[name];
}
