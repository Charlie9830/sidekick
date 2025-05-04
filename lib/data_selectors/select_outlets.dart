import 'package:redux/redux.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/app_state.dart';

class OutletBundle {
  final List<PowerMultiOutletModel> powerOutlets;
  final List<DataPatchModel> dataOutlets;

  OutletBundle({required this.powerOutlets, required this.dataOutlets});
}

OutletBundle selectOutlets(Set<String> outletIds, Store<AppState> store) {
  return OutletBundle(
    powerOutlets: outletIds
        .map((id) => store.state.fixtureState.powerMultiOutlets[id])
        .nonNulls
        .toList(),
    dataOutlets: outletIds
        .map((id) => store.state.fixtureState.dataPatches[id])
        .nonNulls
        .toList(),
  );
}
