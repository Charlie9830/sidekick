import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/redux/models/cable_model.dart';

class PermanentLoomComposition {
  final int powerWays;
  final int dataWays;
  final CableType powerType;
  final CableType dataType;

  const PermanentLoomComposition({
    required this.powerWays,
    required this.powerType,
    required this.dataWays,
    required this.dataType,
  });

  static List<PermanentLoomComposition> matchToPermanents(
      List<CableModel> cables) {
    final singleMatch = matchSuitablePermanent(cables);

    if (singleMatch != null) {
      // A suitable match was found that covers all provided Cables.
      return [singleMatch];
    }

    final powerWayQueue = Queue<CableModel>.from(cables.where((cable) =>
        cable.type == CableType.socapex ||
        cable.type == CableType.wieland6way));

    final dataWayQueue = Queue<CableModel>.from(cables.where((cable) =>
        cable.type == CableType.dmx || cable.type == CableType.sneak));

    final matches = <PermanentLoomComposition>[];

    while (powerWayQueue.isNotEmpty && dataWayQueue.isNotEmpty) {
      final powerWays = powerWayQueue.pop(5);
      final dataWays = dataWayQueue.pop(2);

      final candidate = matchSuitablePermanent([...powerWays, ...dataWays]);

      if (candidate != null) {
        matches.add(candidate);
      }
    }

    return matches;
  }

  static PermanentLoomComposition? matchSuitablePermanent(
      List<CableModel> cables) {
    if (cables.isEmpty) {
      return null;
    }

    if (cables.any((cable) =>
            cable.type == CableType.socapex ||
            cable.type == CableType.wieland6way) ==
        false) {
      // Shouldn't return a Permanent if there are no suitable power ways.
      return null;
    }

    final powerType = cables.any((cable) => cable.type == CableType.socapex)
        ? CableType.socapex
        : CableType.wieland6way;

    final searchCollection =
        powerType == CableType.socapex ? socapexesOnly : wieland6wayOnly;

    return searchCollection.firstWhereOrNull((comp) => comp.satisfied(cables));
  }

  bool satisfied(List<CableModel> cables) {
    final incomingPowerWays = cables
        .where((cable) =>
            cable.type == CableType.socapex ||
            cable.type == CableType.wieland6way)
        .length;
        
    final incomingDmxWays =
        cables.where((cable) => cable.type == CableType.dmx).length;
    final incomingSneakWays =
        cables.where((cable) => cable.type == CableType.sneak).length;

    return incomingPowerWays <= powerWays &&
        _satisfiesDataWays(incomingDmxWays, incomingSneakWays);
  }

  bool _satisfiesDataWays(int dmxWays, int sneakWays) {
    if (dataType == CableType.dmx) {
      return dmxWays <= dataWays;
    }

    return sneakWays <= dataWays;
  }

  String get uid => name;

  String get name =>
      '${powerWays}way ${_humanFriendlyCableType(powerType)} + $dataWays ${_humanFriendlyCableType(dataType)}';

  static Iterable<PermanentLoomComposition> get socapexesOnly =>
      values.where((value) => value.powerType == CableType.socapex);

  static Iterable<PermanentLoomComposition> get wieland6wayOnly =>
      values.where((value) => value.powerType == CableType.wieland6way);

  static const List<PermanentLoomComposition> values = [
    ///
    /// SOCAPEX
    ///

    // 2way
    PermanentLoomComposition(
      powerWays: 2,
      powerType: CableType.socapex,
      dataWays: 2,
      dataType: CableType.dmx,
    ),

    // 3way
    PermanentLoomComposition(
      powerWays: 3,
      powerType: CableType.socapex,
      dataWays: 1,
      dataType: CableType.sneak,
    ),

    // 3way + 2 Sneak
    PermanentLoomComposition(
      powerWays: 3,
      powerType: CableType.socapex,
      dataWays: 1,
      dataType: CableType.sneak,
    ),

    // 5 way
    PermanentLoomComposition(
      powerWays: 5,
      powerType: CableType.socapex,
      dataWays: 1,
      dataType: CableType.sneak,
    ),

    // 5 way + 2 Sneak
    PermanentLoomComposition(
      powerWays: 5,
      powerType: CableType.socapex,
      dataWays: 2,
      dataType: CableType.sneak,
    ),

    ///
    /// 6way
    ///

    // 2way
    PermanentLoomComposition(
      powerWays: 2,
      powerType: CableType.wieland6way,
      dataWays: 2,
      dataType: CableType.dmx,
    ),

    // 3way
    PermanentLoomComposition(
      powerWays: 3,
      powerType: CableType.wieland6way,
      dataWays: 1,
      dataType: CableType.sneak,
    ),

    // 3way + 2 Sneak
    PermanentLoomComposition(
      powerWays: 3,
      powerType: CableType.wieland6way,
      dataWays: 1,
      dataType: CableType.sneak,
    ),

    // 5 way
    PermanentLoomComposition(
      powerWays: 5,
      powerType: CableType.wieland6way,
      dataWays: 1,
      dataType: CableType.sneak,
    ),

    // 5 way + 2 Sneak
    PermanentLoomComposition(
      powerWays: 5,
      powerType: CableType.wieland6way,
      dataWays: 2,
      dataType: CableType.sneak,
    ),
  ];

  static Map<String, PermanentLoomComposition> byName =
      Map<String, PermanentLoomComposition>.fromEntries(
    values.map(
      (comp) => MapEntry(comp.name, comp),
    ),
  );

  String _humanFriendlyCableType(CableType value) {
    return switch (value) {
      CableType.socapex => 'Soca',
      CableType.wieland6way => '6way',
      CableType.dmx => 'DMX',
      CableType.sneak => 'Sneak',
      CableType.unknown => throw 'An unexpected Cable type has been provided.',
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PermanentLoomComposition &&
        other.powerWays == powerWays &&
        other.dataWays == dataWays &&
        other.powerType == powerType &&
        other.dataType == dataType;
  }

  @override
  int get hashCode {
    return powerWays.hashCode ^
        dataWays.hashCode ^
        powerType.hashCode ^
        dataType.hashCode;
  }

  @override
  String toString() {
    return name;
  }
}
