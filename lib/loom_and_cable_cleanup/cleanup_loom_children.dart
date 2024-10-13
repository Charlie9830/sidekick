import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';

/// Ensures that all Ids within each Looms children collection actually exist, and actually point back to the loom.
Map<String, LoomModel> cleanupLoomChildren(
    Map<String, LoomModel> looms, Map<String, CableModel> cables) {
  return looms.map((key, value) {
    return MapEntry(
        key,
        value.copyWith(
            childrenIds: value.childrenIds
                .where((id) => cables[id] != null && cables[id]!.loomId == key)
                .toList()));
  });
}
