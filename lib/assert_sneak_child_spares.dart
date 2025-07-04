import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/utils/get_uid.dart';

Map<String, CableModel> assertSneakChildSpares(Map<String, CableModel> cables) {
  final childrenBySneakId = cables.values
      .where((cable) => cable.parentMultiId.isNotEmpty)
      .groupListsBy((cable) => cable.parentMultiId);

  final invalidQtyEntries =
      childrenBySneakId.entries.where((entry) => entry.value.length < 4);

  if (invalidQtyEntries.isEmpty) {
    return cables;
  }

  final updatedCables = invalidQtyEntries
      .map((entry) {
        final parentMultiId = entry.key;
        final existingChildren = entry.value;

        final parentSneak = cables[parentMultiId];

        if (parentSneak == null) {
          return <CableModel>[];
        }

        final newSpares = List<CableModel>.generate(
            4 - existingChildren.length,
            (index) => CableModel(
                  uid: getUid(),
                  isSpare: true,
                  length: parentSneak.length,
                  isDropper: parentSneak.isDropper,
                  loomId: parentSneak.loomId,
                  parentMultiId: parentMultiId,
                  type: CableType.dmx,
                ));

        return [
          ...existingChildren.where((cable) => cable.isSpare),
          ...newSpares,
        ]
            .mapIndexed((index, cable) => cable.copyWith(spareIndex: index))
            .toList();
      })
      .flattened
      .toList();

  return cables.clone()..addAll(updatedCables.toModelMap());
}
