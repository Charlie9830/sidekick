import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';

/// Removes any Spare cables that do not have a Valid Loom parent.
Map<String, CableModel> cleanupSpareCables(
    Map<String, CableModel> existingCables,
    Map<String, LoomModel> existingLooms) {
  return Map<String, CableModel>.from(existingCables)
    ..removeWhere((key, cable) =>
        cable.isSpare &&
        (cable.loomId.isEmpty ||
            existingLooms.containsKey(cable.loomId) == false));
}
