import 'package:redux/redux.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/state/app_state.dart';

Map<String, Outlet> selectAllOutlets(Store<AppState> store) {
  return [
    ...store.state.fixtureState.powerMultiOutlets.values,
    ...store.state.fixtureState.dataMultis.values,
    ...store.state.fixtureState.dataPatches.values,
    ...store.state.fixtureState.hoists.values,
    ...store.state.fixtureState.hoistMultis.values,
  ].toModelMap();
}
