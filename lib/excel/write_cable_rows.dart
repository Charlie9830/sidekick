import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:sidekick/classes/folded_cable.dart';
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

  final parentWithChildCables =
      FoldedCable.foldCablesIntoSneaks(associatedCables);

  final cableGroupsSortedByType = parentWithChildCables
      .sorted(parentCableTypeComparator)
      .groupListsBy((cable) => cable.cable.type);

  for (final cableList in cableGroupsSortedByType.values) {
    for (final (index, cable) in cableList.indexed) {
      pointer.carriageReturn();
      writeCableLine(
        sheet,
        pointer.getColumnIndex,
        pointer.rowIndex,
        cable.cable,
        index,
        cableRowStyle,
        powerMultiOutlets,
        dataMultis,
        dataPatches,
        locations,
        customRow,
      );

      // Write rows for the Sneak child (if any).
      for (final (childIndex, child) in cable.children.indexed) {
        pointer.carriageReturn();
        writeCableLine(
          sheet,
          pointer.getColumnIndex,
          pointer.rowIndex,
          child,
          childIndex,
          cableRowStyle,
          powerMultiOutlets,
          dataMultis,
          dataPatches,
          locations,
          customRow,
        );
      }
    }
  }
}
