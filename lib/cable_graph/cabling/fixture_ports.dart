import 'package:collection/collection.dart';
import 'package:mvr/mvr.dart';

import 'package:sidekick/cable_graph/cabling/cable_stock.dart';
import 'package:sidekick/cable_graph/cabling/connector_cable_map.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/wiring_object_model.dart';

/// A place on a fixture where a cable plugs in.
class FixturePort {
  /// World position of the connector (mm, Z-up).
  final Vector3 position;

  /// The cable that plugs into this port.
  final CableType cableType;

  const FixturePort({required this.position, required this.cableType});
}

/// The power and data inputs and outputs of one fixture.
class FixturePorts {
  final FixturePort powerIn;
  final FixturePort powerOut;
  final FixturePort dataIn;
  final FixturePort dataOut;

  const FixturePorts({
    required this.powerIn,
    required this.powerOut,
    required this.dataIn,
    required this.dataOut,
  });

  /// The input carrying [signal]: power or data.
  FixturePort inputFor(CableSignal signal) => switch (signal) {
    CableSignal.power => powerIn,
    _ => dataIn,
  };

  /// The output carrying [signal]: power or data.
  FixturePort outputFor(CableSignal signal) => switch (signal) {
    CableSignal.power => powerOut,
    _ => dataOut,
  };
}

/// Resolves where cables plug into [fixture] and which cables they are.
///
/// Each port comes from the first (by name) of [type]'s wiring objects with
/// the matching role and signal. A port with no wiring object sits at the
/// fixture origin, and a connector with no known cable uses the fallback cable
/// (AU10A for power, DMX for data).
///
/// [powerOverride] and [dataOverride] replace the cable of both ports of that
/// signal, leaving their positions untouched.
FixturePorts resolveFixturePorts(
  FixtureModel fixture,
  FixtureTypeModel type, {
  CableType? powerOverride,
  CableType? dataOverride,
}) {
  FixturePort port(GDTFComponentType role, CableSignal signal) {
    final wiringObject = type.wiringObjects
        .where(
          (object) =>
              object.componentType == role &&
              cableSignalFor(object.signalType) == signal,
        )
        .sortedBy((object) => object.name)
        .firstOrNull;
    final override = switch (signal) {
      CableSignal.power => powerOverride,
      _ => dataOverride,
    };

    return FixturePort(
      position: _worldPosition(fixture, wiringObject),
      cableType:
          override ??
          _cableTypeFor(wiringObject, signal) ??
          fallbackCableType(signal),
    );
  }

  return FixturePorts(
    powerIn: port(GDTFComponentType.input, CableSignal.power),
    powerOut: port(GDTFComponentType.output, CableSignal.power),
    dataIn: port(GDTFComponentType.input, CableSignal.data),
    dataOut: port(GDTFComponentType.output, CableSignal.data),
  );
}

/// The connector's cable, provided it carries the port's [signal].
CableType? _cableTypeFor(WiringObjectModel? wiringObject, CableSignal signal) {
  final cableType = cableTypeForConnector(wiringObject?.connectorType);
  return cableType?.signal == signal ? cableType : null;
}

Vector3 _worldPosition(FixtureModel fixture, WiringObjectModel? wiringObject) {
  final local = wiringObject?.matrix;
  final world = fixture.transform.transform(
    local == null ? MVRVector3(0, 0, 0) : MVRVector3(local.x, local.y, local.z),
  );
  return Vector3(world.x, world.y, world.z);
}
