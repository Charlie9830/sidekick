import 'package:flutter_test/flutter_test.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/cable_graph/cabling/connector_cable_map.dart';
import 'package:sidekick/cable_graph/cabling/fixture_ports.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/extension_methods/mvr_matrix_extensions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/wiring_object_model.dart';

/// 90° about Z: local X points along world Y.
final _yaw90 = MVRMatrix([
  [0.0, 1.0, 0.0],
  [-1.0, 0.0, 0.0],
  [0.0, 0.0, 1.0],
  [0.0, 0.0, 0.0],
]);

WiringObjectModel _wiring(
  String name, {
  required GDTFComponentType role,
  required GDTFSignalType signal,
  GDTFConnectorType? connector,
  double localX = 0,
}) => WiringObjectModel(
  name: name,
  componentType: role,
  signalType: signal,
  connectorType: connector,
  matrix: const MVRMatrix.identity().withTranslation(localX, 0, 0),
);

/// A 1 m bar: True1 and DMX in at its -X end, out at its +X end.
final _bar = FixtureTypeModel(
  uid: 'bar',
  wiringObjects: [
    _wiring(
      'Power In',
      role: GDTFComponentType.input,
      signal: GDTFPredefinedSignalType.power,
      connector: GDTFPredefinedConnectorType.powerconTrue1,
      localX: -500,
    ),
    _wiring(
      'Power Out',
      role: GDTFComponentType.output,
      signal: GDTFPredefinedSignalType.power,
      connector: GDTFPredefinedConnectorType.powerconTrue1Top,
      localX: 500,
    ),
    _wiring(
      'DMX In',
      role: GDTFComponentType.input,
      signal: GDTFPredefinedSignalType.dmx512,
      connector: GDTFPredefinedConnectorType.xlr5,
      localX: -500,
    ),
    _wiring(
      'DMX Out',
      role: GDTFComponentType.output,
      signal: GDTFPredefinedSignalType.dmx512,
      connector: GDTFPredefinedConnectorType.xlr5,
      localX: 500,
    ),
  ],
);

void expectAt(FixturePort port, Vector3 expected) {
  expect(port.position.x, closeTo(expected.x, 1e-9));
  expect(port.position.y, closeTo(expected.y, 1e-9));
  expect(port.position.z, closeTo(expected.z, 1e-9));
}

void main() {
  group('cableTypeForConnector', () {
    test('maps predefined connectors', () {
      expect(
        cableTypeForConnector(GDTFPredefinedConnectorType.powerconTrue1),
        CableType.true1,
      );
      expect(
        cableTypeForConnector(GDTFPredefinedConnectorType.powerconTrue1Top),
        CableType.true1,
      );
      expect(
        cableTypeForConnector(GDTFPredefinedConnectorType.nac3fca),
        CableType.nac3,
      );
      expect(
        cableTypeForConnector(GDTFPredefinedConnectorType.xlr5),
        CableType.dmx,
      );
    });

    test('maps custom names regardless of case, spaces and hyphens', () {
      for (final name in ['powerCON TRUE1', 'True-1', 'powercon_true1']) {
        expect(
          cableTypeForConnector(GDTFCustomConnectorType(name)),
          CableType.true1,
          reason: name,
        );
      }
      expect(
        cableTypeForConnector(WiringObjectModel.au10aConnectorType),
        CableType.au10a,
      );
    });

    test('unknown or missing connectors map to nothing', () {
      expect(cableTypeForConnector(GDTFCustomConnectorType('etherCON')), null);
      expect(cableTypeForConnector(GDTFPredefinedConnectorType.rj45), null);
      expect(cableTypeForConnector(null), null);
    });
  });

  group('resolveFixturePorts', () {
    test('fixtures without GDTF wiring get AU10A and DMX at their origin', () {
      final fixture = FixtureModel(x: 100, y: 200, z: 300);

      final ports = resolveFixturePorts(fixture, FixtureTypeModel(uid: 't'));

      expect(ports.powerIn.cableType, CableType.au10a);
      expect(ports.powerOut.cableType, CableType.au10a);
      expect(ports.dataIn.cableType, CableType.dmx);
      expect(ports.dataOut.cableType, CableType.dmx);
      for (final port in [
        ports.powerIn,
        ports.powerOut,
        ports.dataIn,
        ports.dataOut,
      ]) {
        expectAt(port, const Vector3(100, 200, 300));
      }
    });

    test('ports follow the connectors and their GDTF cables', () {
      final ports = resolveFixturePorts(FixtureModel(x: 1000), _bar);

      expect(ports.powerIn.cableType, CableType.true1);
      expect(ports.powerOut.cableType, CableType.true1);
      expect(ports.dataIn.cableType, CableType.dmx);
      expectAt(ports.powerIn, const Vector3(500, 0, 0));
      expectAt(ports.powerOut, const Vector3(1500, 0, 0));
    });

    test('connector positions rotate with the fixture', () {
      final fixture = FixtureModel(x: 1000, rotation: _yaw90);

      final ports = resolveFixturePorts(fixture, _bar);

      expectAt(ports.powerIn, const Vector3(1000, -500, 0));
      expectAt(ports.dataOut, const Vector3(1000, 500, 0));
    });

    test('a connector carrying the wrong signal falls back', () {
      final type = FixtureTypeModel(
        uid: 't',
        wiringObjects: [
          _wiring(
            'Power In',
            role: GDTFComponentType.input,
            signal: GDTFPredefinedSignalType.power,
            connector: GDTFPredefinedConnectorType.xlr5,
          ),
        ],
      );

      final ports = resolveFixturePorts(FixtureModel(), type);

      expect(ports.powerIn.cableType, CableType.au10a);
    });

    test('duplicate connectors resolve to the first by name', () {
      final type = FixtureTypeModel(
        uid: 't',
        wiringObjects: [
          _wiring(
            'Power In B',
            role: GDTFComponentType.input,
            signal: GDTFPredefinedSignalType.power,
            connector: GDTFPredefinedConnectorType.nac3fca,
            localX: 900,
          ),
          _wiring(
            'Power In A',
            role: GDTFComponentType.input,
            signal: GDTFPredefinedSignalType.power,
            connector: GDTFPredefinedConnectorType.powerconTrue1,
            localX: -900,
          ),
        ],
      );

      final ports = resolveFixturePorts(FixtureModel(), type);

      expect(ports.powerIn.cableType, CableType.true1);
      expectAt(ports.powerIn, const Vector3(-900, 0, 0));
    });

    test('overrides change the cable but not where it plugs in', () {
      final ports = resolveFixturePorts(
        FixtureModel(),
        _bar,
        powerOverride: CableType.au10a,
      );

      expect(ports.powerIn.cableType, CableType.au10a);
      expect(ports.powerOut.cableType, CableType.au10a);
      expectAt(ports.powerIn, const Vector3(-500, 0, 0));
      expect(ports.dataIn.cableType, CableType.dmx);
    });
  });
}
