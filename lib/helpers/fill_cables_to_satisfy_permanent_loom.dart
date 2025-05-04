import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/utils/get_uid.dart';

List<CableModel> fillCablesToSatisfyPermanentLoom(
    LoomModel loom, List<CableModel> children) {
  if (loom.type.type != LoomType.permanent) {
    return [];
  }

  final topLevelChildren =
      children.where((child) => child.parentMultiId.isEmpty).toList();
  final composition =
      PermanentLoomComposition.byName[loom.type.permanentComposition];

  if (composition == null) {
    return [];
  }

  final socaShortages = composition.socaWays -
      topLevelChildren.where((cable) => cable.type == CableType.socapex).length;
  final wieland6wayShortages = composition.wieland6Ways -
      topLevelChildren
          .where((cable) => cable.type == CableType.wieland6way)
          .length;
  final dmxShortages = composition.dmxWays -
      topLevelChildren.where((cable) => cable.type == CableType.dmx).length;
  final sneakShortages = composition.sneakWays -
      topLevelChildren.where((cable) => cable.type == CableType.sneak).length;

  // Builder function to handle multiple simliar calls.
  spareCableBuilder(int index, CableType type) => CableModel(
        uid: getUid(),
        type: type,
        isSpare: true,
        spareIndex: children
                .where((cable) => cable.type == type && cable.isSpare)
                .length +
            index,
        length: loom.type.length,
        loomId: loom.uid,
      );

  return [
    // Socapex
    ...List<CableModel>.generate(
      socaShortages.abs(),
      (index) => spareCableBuilder(index, CableType.socapex),
    ),

    // Wieland 6way.
    ...List<CableModel>.generate(
      wieland6wayShortages.abs(),
      (index) => spareCableBuilder(index, CableType.wieland6way),
    ),

    // DMX
    ...List<CableModel>.generate(
      dmxShortages.abs(),
      (index) => spareCableBuilder(index, CableType.dmx),
    ),

    // Sneak
    ...List<CableModel>.generate(
      sneakShortages.abs(),
      (index) => spareCableBuilder(index, CableType.sneak),
    ),
  ];
}
