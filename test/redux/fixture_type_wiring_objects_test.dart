import 'package:flutter_test/flutter_test.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/wiring_object_model.dart';

void main() {
  test('fixture types default to power in, DMX in and DMX out', () {
    final type = FixtureTypeModel(uid: 'type');

    expect(
      type.wiringObjects.map(
        (object) =>
            (object.connectorType, object.componentType, object.signalType),
      ),
      [
        (
          WiringObjectModel.au10aConnectorType,
          GDTFComponentType.input,
          GDTFPredefinedSignalType.power,
        ),
        (
          GDTFPredefinedConnectorType.xlr5,
          GDTFComponentType.input,
          GDTFPredefinedSignalType.dmx512,
        ),
        (
          GDTFPredefinedConnectorType.xlr5,
          GDTFComponentType.output,
          GDTFPredefinedSignalType.dmx512,
        ),
      ],
    );
  });

  test('the AU10A default connector survives a JSON round trip', () {
    final restored = FixtureTypeModel.fromJson(
      FixtureTypeModel(uid: 'type').toJson(),
    );

    expect(
      restored.wiringObjects.first.connectorType,
      WiringObjectModel.au10aConnectorType,
    );
  });

  test('files saved without wiring objects load the defaults', () {
    final type = FixtureTypeModel.fromMap({'uid': 'type', 'amps': 1.0});

    expect(type.wiringObjects, WiringObjectModel.defaultWiringObjects);
  });

  test('wiring objects survive a JSON round trip', () {
    final original = FixtureTypeModel(
      uid: 'type',
      wiringObjects: [
        WiringObjectModel(
          name: 'Ethernet',
          matrix: MVRMatrix([
            [0, 1, 0],
            [-1, 0, 0],
            [0, 0, 1],
            [12.5, -40, 310],
          ]),
          connectorType: const GDTFCustomConnectorType('etherCON'),
          componentType: GDTFComponentType.networkInOut,
          signalType: const GDTFCustomSignalType('Ethernet'),
        ),
        const WiringObjectModel(name: 'Fuse'),
      ],
    );

    final restored = FixtureTypeModel.fromJson(original.toJson());
    final [ethernet, fuse] = restored.wiringObjects;

    expect(ethernet.name, 'Ethernet');
    expect(ethernet.matrix.matrix, original.wiringObjects.first.matrix.matrix);
    expect(ethernet.connectorType, const GDTFCustomConnectorType('etherCON'));
    expect(ethernet.componentType, GDTFComponentType.networkInOut);
    expect(ethernet.signalType, const GDTFCustomSignalType('Ethernet'));
    expect(fuse.connectorType, isNull);
    expect(fuse.componentType, isNull);
    expect(fuse.signalType, isNull);
  });

  test('malformed matrices fall back to identity', () {
    final object = WiringObjectModel.fromMap({
      'matrix': [
        [1, 0],
      ],
    });

    expect(object.matrix.matrix, const MVRMatrix.identity().matrix);
  });
}
