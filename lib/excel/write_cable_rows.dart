import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/excel/cable_type_ordering.dart';
import 'package:sidekick/excel/sheet_indexer.dart';
import 'package:sidekick/excel/styles.dart';
import 'package:sidekick/excel/write_cable_line.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

void writeCableRows({
  required LoomModel loom,
  required Map<String, CableModel> cables,
  required Map<String, LocationModel> locations,
  required Map<String, PowerMultiOutletModel> powerMultiOutlets,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  required SheetIndexer pointer,
  required Sheet sheet,
  bool customRow = false,
}) {
  final associatedCables = cables.values
      .where((cable) => cable.loomId == loom.uid)
      .map((cable) => cables[cable.uid])
      .nonNulls
      .toList();

  final cablesByType = associatedCables.groupListsBy((element) => element.type);

  final cablesSortedByType =
      cableTypeOrdering.map((type) => cablesByType[type] ?? []);

  for (final cableList in cablesSortedByType) {
    for (final (index, cable) in cableList.indexed) {
      pointer.carriageReturn();
      writeCableLine(
        sheet,
        pointer.getColumnIndex,
        pointer.rowIndex,
        cable,
        index,
        cableRowStyle,
        powerMultiOutlets,
        dataMultis,
        dataPatches,
        locations,
        customRow,
      );

      // TODO: Disabled until refactoring to Cable based Sneak children is complete.
      // if (cable.type == CableType.sneak) {
      //   // We need to write the children of the sneak.
      //   final children = dataPatches.values
      //       .where((patch) => patch.multiId == cable.outletId);

      //   int spareIndex = 1;
      //   final childrenAsCables = children.map((child) => CableModel(
      //         type: CableType.dmx,
      //         uid: '',
      //         locationId: child.locationId,
      //         outletId: child.uid,
      //         upstreamId: '',
      //         isSpare: child.isSpare,
      //         spareIndex: child.isSpare ? spareIndex++ : 0,
      //       ));

      //   for (final (sneakIndex, sneakPatch) in childrenAsCables.indexed) {
      //     pointer.carriageReturn();
      //     writeCableLine(
      //       sheet,
      //       pointer.getColumnIndex,
      //       pointer.rowIndex,
      //       sneakPatch,
      //       sneakIndex,
      //       cableRowStyle,
      //       powerMultiOutlets,
      //       dataMultis,
      //       dataPatches,
      //       locations,
      //       customRow,
      //     );
      //   }
      // }
    }
  }
}
