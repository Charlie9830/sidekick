import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/redux/models/cable_model.dart';

class PermanentLoomComposition {
  final int socaWays;
  final int wieland6Ways;
  final int dmxWays;
  final int sneakWays;

  const PermanentLoomComposition._({
    required this.socaWays,
    required this.wieland6Ways,
    required this.dmxWays,
    required this.sneakWays,
  });

  String get uid => name;

  String get name => _buildName();

  int get powerWays => socaWays != 0 ? socaWays : wieland6Ways;

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

    return values.firstWhereOrNull((comp) => comp.satisfied(cables));
  }

  bool satisfied(List<CableModel> cables) {
    final incomingSoca =
        cables.where((cable) => cable.type == CableType.socapex).length;
    final incomingWieland6way =
        cables.where((cable) => cable.type == CableType.wieland6way).length;
    final incomingDmx =
        cables.where((cable) => cable.type == CableType.dmx).length;
    final incomingSneak =
        cables.where((cable) => cable.type == CableType.sneak).length;

    final socaSatisfied =
        incomingWieland6way > 0 ? false : incomingSoca <= socaWays;
    final wieland6Satisfied =
        incomingSoca > 0 ? false : incomingWieland6way <= wieland6Ways;
    final dmxSatisfied = incomingSneak > 0 ? false : incomingDmx <= dmxWays;
    final sneakSatisfied = incomingDmx > 0 ? false : incomingSneak <= sneakWays;

    return (socaSatisfied || wieland6Satisfied) &&
        (sneakSatisfied || dmxSatisfied);
  }

  String _buildName() {
    String name = '';

    if (socaWays > 0) {
      name = '$name$socaWays Soca ';
    }

    if (wieland6Ways > 0) {
      name = '$name$wieland6Ways 6way ';
    }

    if (dmxWays > 0) {
      name = '$name+ $dmxWays DMX';
    }

    if (sneakWays > 0) {
      name = '$name+ $sneakWays Sneak';
    }

    return name;
  }

  static const List<PermanentLoomComposition> values = [
    // 2 way Socapex + 2 DMX.
    PermanentLoomComposition._(
      socaWays: 2,
      wieland6Ways: 0,
      dmxWays: 2,
      sneakWays: 0,
    ),

    // 3 way Socapex + Sneak.
    PermanentLoomComposition._(
      socaWays: 3,
      wieland6Ways: 0,
      dmxWays: 0,
      sneakWays: 1,
    ),

    // 5 way Socapex + Sneak.
    PermanentLoomComposition._(
      socaWays: 5,
      wieland6Ways: 0,
      dmxWays: 0,
      sneakWays: 1,
    ),

    // 5 way Socapex + 2 Sneak.
    PermanentLoomComposition._(
      socaWays: 5,
      wieland6Ways: 0,
      dmxWays: 0,
      sneakWays: 2,
    ),

    // 2 way 6way + 2 DMX.
    PermanentLoomComposition._(
      socaWays: 0,
      wieland6Ways: 2,
      dmxWays: 2,
      sneakWays: 0,
    ),

    // 3 way 6way + Sneak.
    PermanentLoomComposition._(
      socaWays: 0,
      wieland6Ways: 2,
      dmxWays: 0,
      sneakWays: 1,
    ),

    // 5 way 6way + Sneak.
    PermanentLoomComposition._(
      socaWays: 0,
      wieland6Ways: 5,
      dmxWays: 0,
      sneakWays: 2,
    ),

    // 5 way 6way + 2x Sneak.
    PermanentLoomComposition._(
      socaWays: 0,
      wieland6Ways: 5,
      dmxWays: 0,
      sneakWays: 2,
    ),
  ];

  static Map<String, PermanentLoomComposition> byName =
      Map<String, PermanentLoomComposition>.fromEntries(
    values.map(
      (comp) => MapEntry(comp.name, comp),
    ),
  );

  @override
  String toString() {
    return name;
  }
}
