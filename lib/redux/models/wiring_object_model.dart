import 'package:mvr/mvr.dart';

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
      'matrix': _matrixToJson(matrix),
      'connectorType': connectorType?.xmlValue,
      'componentType': componentType?.xmlValue,
      'signalType': signalType?.xmlValue,
    };
  }

  factory WiringObjectModel.fromMap(Map<String, dynamic> map) {
    return WiringObjectModel(
      name: (map['name'] ?? '') as String,
      matrix: _matrixFromJson(map['matrix']),
      connectorType: GDTFConnectorType.fromXmlValue(
        map['connectorType'] as String?,
      ),
      componentType: GDTFComponentType.fromXmlValue(
        map['componentType'] as String?,
      ),
      signalType: GDTFSignalType.fromXmlValue(map['signalType'] as String?),
    );
  }

  /// Serializes [matrix] as its four rows of three doubles.
  ///
  /// [MVRMatrix] has no JSON support of its own, but its backing
  /// `List<List<double>>` encodes directly. The rows are copied so the map
  /// never aliases the matrix's mutable lists.
  static List<List<double>> _matrixToJson(MVRMatrix matrix) => [
    for (final row in matrix.matrix) [...row],
  ];

  /// Parses a 4x3 matrix serialized by [toMap], falling back to identity when
  /// the value is missing or malformed so a bad entry cannot break file load.
  static MVRMatrix _matrixFromJson(Object? value) {
    if (value is! List || value.length != 4) {
      return const MVRMatrix.identity();
    }

    final rows = [
      for (final row in value)
        if (row is List && row.length == 3 && row.every((cell) => cell is num))
          [for (final cell in row) (cell as num).toDouble()],
    ];

    return rows.length == 4 ? MVRMatrix(rows) : const MVRMatrix.identity();
  }
}
