import 'package:sidekick/loom_and_cable_cleanup/cleanup_loom_children.dart';
import 'package:sidekick/loom_and_cable_cleanup/cleanup_spare_cables.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';

(
  Map<String, CableModel> cables,
  Map<String, LoomModel> looms
) cleanupCablesAndLooms(
    Map<String, CableModel> dirtyCables, Map<String, LoomModel> dirtyLooms) {
  final cleanCables = cleanupSpareCables(dirtyCables, dirtyLooms);
  final cleanLooms = cleanupLoomChildren(dirtyLooms, cleanCables);

  return (cleanCables, cleanLooms);
}
