import 'package:mvr/mvr.dart';
import 'package:sidekick/extension_methods/mvr_matrix_extensions.dart';

/// An electrical connection point of a fixture type, such as a power input or
/// a DMX thru, captured from a GDTF `WiringObject`.
///
/// Fixture types without GDTF wiring data fall back to
/// [defaultWiringObjects].
class WiringObjectModel {
  /// The GDTF geometry name of the wiring object, e.g. 'DMX In'.
  ///
  /// Not guaranteed unique: a wiring object inside a referenced geometry
  /// yields one instance per reference.
  final String name;

  /// The transform of the wiring object in fixture-local space.
  ///
  /// Accumulated from the root of the fixture's geometry tree, so it is
  /// relative to the fixture origin (the centre of its base) rather than the
  /// wiring object's immediate parent node. Follows MVR conventions: basis
  /// vectors in rows 0-2, translation in row 3, mm, right-handed, Z-up.
  final MVRMatrix matrix;

  /// The physical connector, or null when the GDTF does not specify one.
  final GDTFConnectorType? connectorType;

  /// The electrical role, or null when absent or unrecognised.
  final GDTFComponentType? componentType;

  /// The signal carried, or null when not specified.
  ///
  /// Distinguishes objects that share a [componentType], e.g. a power input
  /// from a DMX input.
  final GDTFSignalType? signalType;

  const WiringObjectModel({
    this.name = '',
    this.matrix = const MVRMatrix.identity(),
    this.connectorType,
    this.componentType,
    this.signalType,
  });

  /// An Australian 10A (AS/NZS 3112) power connector.
  ///
  /// Not one of the GDTF Annex D predefined types, so it is represented as a
  /// custom connector type.
  static const au10aConnectorType = GDTFCustomConnectorType('AU10A');

  /// The wiring assumed for fixture types without GDTF wiring data: an AU10A
  /// power input, a DMX512 input and a DMX512 output, all at the fixture
  /// origin.
  static const defaultWiringObjects = [
    WiringObjectModel(
      name: 'Power In',
      connectorType: au10aConnectorType,
      componentType: GDTFComponentType.input,
      signalType: GDTFPredefinedSignalType.power,
    ),
    WiringObjectModel(
      name: 'DMX In',
      connectorType: GDTFPredefinedConnectorType.xlr5,
      componentType: GDTFComponentType.input,
      signalType: GDTFPredefinedSignalType.dmx512,
    ),
    WiringObjectModel(
      name: 'DMX Out',
      connectorType: GDTFPredefinedConnectorType.xlr5,
      componentType: GDTFComponentType.output,
      signalType: GDTFPredefinedSignalType.dmx512,
    ),
  ];

  /// Creates a model from a wiring object placed in fixture-local space.
  factory WiringObjectModel.fromInstance(GDTFWiringObjectInstance instance) {
    final wiringObject = instance.wiringObject;

    return WiringObjectModel(
      name: wiringObject.name,
      matrix: instance.transform,
      connectorType: wiringObject.connectorType,
      componentType: wiringObject.componentType,
      signalType: wiringObject.signalType,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'matrix': matrix.toJson(),
      'connectorType': connectorType?.xmlValue,
      'componentType': componentType?.xmlValue,
      'signalType': signalType?.xmlValue,
    };
  }

  factory WiringObjectModel.fromMap(Map<String, dynamic> map) {
    return WiringObjectModel(
      name: (map['name'] ?? '') as String,
      matrix: MVRMatrixExtensions.fromJson(map['matrix']),
      connectorType: GDTFConnectorType.fromXmlValue(
        map['connectorType'] as String?,
      ),
      componentType: GDTFComponentType.fromXmlValue(
        map['componentType'] as String?,
      ),
      signalType: GDTFSignalType.fromXmlValue(map['signalType'] as String?),
    );
  }
}
