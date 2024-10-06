import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/looms/looms.dart';
import 'package:sidekick/view_models/loom_screen_item_view_model.dart';
import 'package:sidekick/view_models/looms_view_model.dart';

class LoomsContainer extends StatelessWidget {
  const LoomsContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LoomsViewModel>(
        builder: (context, viewModel) {
      return Looms(
        vm: viewModel,
      );
    }, converter: (Store<AppState> store) {
      return LoomsViewModel(
          selectedCableIds: store.state.navstate.selectedCableIds,
          selectCables: (ids) => store.dispatch(SetSelectedCableIds(ids)),
          onGenerateLoomsButtonPressed: () => store.dispatch(generateCables()),
          rowVms: _selectRows(store),
          onCombineCablesIntoNewLoomButtonPressed: (type) => store.dispatch(
              combineCablesIntoNewLoom(context, store.state.navstate.selectedCableIds, type)),
          onCreateExtensionFromSelection: () => store.dispatch(createExtensionFromSelection(context, store.state.navstate.selectedCableIds)));
    });
  }

  List<LoomScreenItemViewModel> _selectRows(Store<AppState> store) {
    final cablesAndLoomsByLocation =
        store.state.fixtureState.locations.map((locationId, location) {
      final cablesInLocation = store.state.fixtureState.cables.values
          .where((cable) => cable.locationId == locationId);

      final loomsInLocation = store.state.fixtureState.looms.values
          .where((loom) => loom.locationIds.contains(locationId));

      final nakedCables =
          cablesInLocation.where((cable) => cable.loomId.isEmpty);

      return MapEntry(location, [
        // Naked Cables
        ...nakedCables.map((cable) => CableViewModel(
              cable: cable,
              locationId: location.uid,
              labelColor: NamedColors.names[location.color] ?? '',
              isExtension: cable.upstreamId.isNotEmpty,
            )),

        // Looms
        ...loomsInLocation.map((loom) => LoomViewModel(
              loom: loom,
              children: cablesInLocation
                  .where((cable) => cable.loomId == loom.uid)
                  .map((cable) => CableViewModel(
                        cable: cable,
                        locationId: location.uid,
                        labelColor: NamedColors.names[location.color] ?? '',
                        isExtension: cable.upstreamId.isNotEmpty,
                      ))
                  .toList(),
                onNameChanged: (newValue) => store.dispatch(UpdateLoomName(loom.uid, newValue)),
                onLengthChanged: (newValue) => store.dispatch(UpdateLoomLength(loom.uid, newValue)),
                
            ))
      ]);
    });

    return cablesAndLoomsByLocation.entries
        .map((entry) {
          final location = entry.key;
          final cablesAndLooms = entry.value;

          return [
            LocationDividerViewModel(location: location),
            ...cablesAndLooms,
          ];
        })
        .flattened
        .toList();
  }
}
