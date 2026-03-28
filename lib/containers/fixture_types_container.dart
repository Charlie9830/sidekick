import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/screens/fixture_types/fixture_types.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';

class FixtureTypesContainer extends StatelessWidget {
  const FixtureTypesContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, FixtureTypesViewModel>(
      builder: (context, viewModel) {
        return FixtureTypes(
          vm: viewModel,
        );
      },
      converter: (Store<AppState> store) {
        final inUseFixtureTypeIds = _selectInUseFixtureTypeIds(store);
        final fixtureTypeVms =
            _selectFixtureTypeVms(store, inUseFixtureTypeIds);

        return FixtureTypesViewModel(
            fixtureTypeVms: fixtureTypeVms.values.toList(),
            showAllFixtureTypes: store.state.navstate.showAllFixtureTypes,
            tabIndex: store.state.navstate.fixtureTypesTabIndex,
            onTabChanged: (index) =>
                store.dispatch(SetFixtureTypesTabIndex(index)),
            onShowAllFixtureTypesChanged: (newValue) =>
                store.dispatch(SetShowAllFixtureTypes(newValue)),
            itemsById: _selectItemsById(store, inUseFixtureTypeIds),
            poolVms: _selectPoolVms(store, fixtureTypeVms),
            onCreatePoolButtonPressed: () =>
                store.dispatch(createFixtureTypePool()),
            onPoolReorder: (oldIndex, newIndex) => store.dispatch(
                ReorderFixtureTypePools(
                    oldIndex: oldIndex, newIndex: newIndex)));
      },
    );
  }

  List<FixtureTypePoolViewModel> _selectPoolVms(
      Store<AppState> store, Map<String, FixtureTypeViewModel> fixtureTypeVms) {
    return store.state.fixtureState.fixtureTypePools.values
        .map(
          (pool) => FixtureTypePoolViewModel(
            pool: pool,
            onPoolDeleted: () =>
                store.dispatch(DeleteFixtureTypePool(pool.uid)),
            childVms: pool.items.values
                .map(
                  (item) => FixtureTypePoolEntryViewModel(
                    entry: item,
                    fixtureType: fixtureTypeVms[item.typeId]!,
                    onRemoveFixturePressed: () =>
                        store.dispatch(RemoveFixtureTypePoolEntry(
                      poolId: pool.uid,
                      typeId: item.typeId,
                    )),
                    onQtyChanged: (newValue) => store.dispatch(
                      UpdateFixtureTypePoolEntryQty(
                          poolId: pool.uid,
                          typeId: item.typeId,
                          newValue: newValue),
                    ),
                  ),
                )
                .nonNulls
                .toList(),
            onAddFixturesToPool: (ids) => store.dispatch(
              AddFixtureTypesToPool(poolId: pool.uid, typeIds: ids.toList()),
            ),
            onNameChanged: (newValue) =>
                store.dispatch(UpdateFixtureTypePoolName(pool.uid, newValue)),
          ),
        )
        .toList();
  }

  Map<String, ItemData<String, FixtureTypeModel>> _selectItemsById(
      Store<AppState> store, Set<String> inUseFixtureTypeIds) {
    return Map<String, ItemData<String, FixtureTypeModel>>.fromEntries(
      inUseFixtureTypeIds.map(
        (id) => MapEntry(
          id,
          ItemData(id: id, item: store.state.fixtureState.fixtureTypes[id]!),
        ),
      ),
    );
  }

  Set<String> _selectInUseFixtureTypeIds(Store<AppState> store) {
    return store.state.fixtureState.fixtures.values
        .map((fixture) => fixture.typeId)
        .toSet();
  }

  Map<String, FixtureTypeViewModel> _selectFixtureTypeVms(
      Store<AppState> store, Set<String> inUseFixtureTypeIds) {
    List<FixtureTypeModel> fixtureTypes;
    if (store.state.navstate.showAllFixtureTypes) {
      fixtureTypes = store.state.fixtureState.fixtureTypes.values.toList();
    } else {
      fixtureTypes = inUseFixtureTypeIds
          .map((id) => store.state.fixtureState.fixtureTypes[id]!)
          .toList();
    }

    return fixtureTypes
        .map((type) => FixtureTypeViewModel(
              qty: store.state.fixtureState.fixtures.values
                  .where((fixture) => fixture.typeId == type.uid)
                  .length,
              type: type,
              onMaxPairingsChanged: (newValue) => store
                  .dispatch(UpdateFixtureTypeMaxPiggybacks(type.uid, newValue)),
              onShortNameChanged: (newValue) => store
                  .dispatch(UpdateFixtureTypeShortName(type.uid, newValue)),
            ))
        .toModelMap();
  }
}
