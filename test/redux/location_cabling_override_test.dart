import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_type_cabling_override.dart';
import 'package:sidekick/redux/models/location_override_model.dart';

void main() {
  test('cabling overrides survive a toMap/fromMap round trip', () {
    final overrides = const LocationOverrideModel.none().withCabling(
      'bar',
      const FixtureTypeCablingOverride(power: CableType.au10a),
    );

    final restored = LocationOverrideModel.fromMap(overrides.toMap());

    expect(restored.getCabling('bar').power, CableType.au10a);
    expect(restored.getCabling('bar').data, isNull);
    expect(restored.hasOverrides, isTrue);
  });

  test('a non-default orientation is kept and survives a round trip', () {
    final overrides = const LocationOverrideModel.none().withCabling(
      'bar',
      const FixtureTypeCablingOverride(
        orientation: ChainOrientation.foldBackLinks,
      ),
    );

    final restored = LocationOverrideModel.fromMap(overrides.toMap());

    expect(
      restored.getCabling('bar').orientation,
      ChainOrientation.foldBackLinks,
    );
  });

  test('overrides default to homing to the furthest fixture', () {
    expect(
      const LocationOverrideModel.none().getCabling('bar').orientation,
      ChainOrientation.homeRunToFurthest,
    );
  });

  test('clearing the last cable removes the override entirely', () {
    final overrides = const LocationOverrideModel.none()
        .withCabling(
          'bar',
          const FixtureTypeCablingOverride(power: CableType.au10a),
        )
        .withCabling('bar', const FixtureTypeCablingOverride.none());

    expect(overrides.cabling, isEmpty);
    expect(overrides.hasOverrides, isFalse);
  });

  test('files without cabling overrides load with none', () {
    final map = const LocationOverrideModel.none().toMap()..remove('cabling');

    expect(LocationOverrideModel.fromMap(map).cabling, isEmpty);
  });

  test('unknown cable names are ignored rather than failing the load', () {
    final override = FixtureTypeCablingOverride.fromMap({
      'power': 'someFutureCable',
      'data': 'dmx',
    });

    expect(override.power, isNull);
    expect(override.data, CableType.dmx);
  });
}
