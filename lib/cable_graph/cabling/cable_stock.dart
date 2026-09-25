import 'package:sidekick/redux/models/cable_model.dart';

/// Stock cable lengths held in inventory, in metres, ascending.
abstract final class CableLengthBreakpoints {
  static const au10A = <double>[1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  static const motorMulti = <double>[5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  static const socapex = <double>[
    2, 3, 5, 7.5, 10, 12.5, 15, 17.5, 20, 25, 30, 35, 40, 45, 50, //
  ];
  static const wieland6Way = socapex;
  static const dmx = <double>[1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  static const true1 = <double>[0.7, 1, 2, 3, 5, 10, 15];
  static const sneak = <double>[2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  static const nac3 = <double>[0.5, 1, 2, 3, 5, 10];
  static const consoleLoom = <double>[5, 10];
}

/// What a cable carries.
enum CableSignal { power, data, network, hoist, none }

/// Inventory facts about each [CableType].
extension CableTypeStock on CableType {
  /// What this cable (or adaptor, or header) carries.
  CableSignal get signal => switch (this) {
    CableType.au10a ||
    CableType.true1 ||
    CableType.nac3 ||
    CableType.nac3Joiner ||
    CableType.socapex ||
    CableType.wieland6way ||
    CableType.wilco32a ||
    CableType.socapexToAu10ALampHeader ||
    CableType.socapexToTrue1LampHeader ||
    CableType.socapexTo6wayAdaptor ||
    CableType.wieland6WayLampHeader ||
    CableType.wieland6WayRackHeader ||
    CableType.au10aToTrue1Adaptor ||
    CableType.au10aToNac3Adaptor => CableSignal.power,
    CableType.dmx ||
    CableType.sneak ||
    CableType.sneakLampHeader ||
    CableType.sneakRackHeader => CableSignal.data,
    CableType.ethercon ||
    CableType.etherconJoiner ||
    CableType.consoleLoom => CableSignal.network,
    CableType.hoist ||
    CableType.hoistMulti ||
    CableType.hoistMultiLampHeader ||
    CableType.hoistMultiRackHeader => CableSignal.hoist,
    CableType.unknown => CableSignal.none,
  };

  /// The stock lengths this cable comes in, in metres.
  ///
  /// Empty for fixed adaptors and headers, which have no length.
  List<double> get stockLengths => switch (this) {
    CableType.au10a => CableLengthBreakpoints.au10A,
    CableType.true1 => CableLengthBreakpoints.true1,
    CableType.nac3 => CableLengthBreakpoints.nac3,
    CableType.socapex || CableType.wilco32a => CableLengthBreakpoints.socapex,
    CableType.wieland6way => CableLengthBreakpoints.wieland6Way,
    CableType.dmx => CableLengthBreakpoints.dmx,
    CableType.sneak || CableType.ethercon => CableLengthBreakpoints.sneak,
    CableType.hoist ||
    CableType.hoistMulti => CableLengthBreakpoints.motorMulti,
    CableType.consoleLoom => CableLengthBreakpoints.consoleLoom,
    CableType.unknown ||
    CableType.socapexToAu10ALampHeader ||
    CableType.socapexToTrue1LampHeader ||
    CableType.socapexTo6wayAdaptor ||
    CableType.wieland6WayLampHeader ||
    CableType.wieland6WayRackHeader ||
    CableType.sneakLampHeader ||
    CableType.sneakRackHeader ||
    CableType.hoistMultiLampHeader ||
    CableType.hoistMultiRackHeader ||
    CableType.nac3Joiner ||
    CableType.etherconJoiner ||
    CableType.au10aToTrue1Adaptor ||
    CableType.au10aToNac3Adaptor => const [],
  };
}

/// Rounds a routed length in mm up to the shortest stock length (metres) that
/// covers it.
///
/// Lengths beyond the longest stock length are clamped to it.
double roundUpToStock(double lengthMm, List<double> stockLengthsMetres) {
  assert(
    stockLengthsMetres.isNotEmpty,
    'A cable needs at least 1 stock length',
  );
  final metres = (lengthMm.ceilToDouble() * 0.001).clamp(0.0, double.infinity);

  return stockLengthsMetres.firstWhere(
    (stock) => stock >= metres,
    orElse: () => stockLengthsMetres.last,
  );
}
