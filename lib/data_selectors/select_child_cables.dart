import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

List<CableModel> selectChildCables(
    CableModel parentCable, FixtureState fixtureState) {

  return parentCable.isMultiCable
      ? fixtureState.cables.values
          .where((child) => child.parentMultiId == parentCable.uid)
          .toList()
      : const [];
}
