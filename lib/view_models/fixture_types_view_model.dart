import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';

class FixtureTypesViewModel {
  final List<FixtureTypeViewModel> fixtureTypeVms;
  final List<FixtureTypePoolViewModel> poolVms;
  final void Function(bool newValue) onShowAllFixtureTypesChanged;
  final bool showAllFixtureTypes;
  final int tabIndex;
  final void Function(int index) onTabChanged;
  final Map<String, ItemData<String, FixtureTypeModel>> itemsById;
  final void Function() onCreatePoolButtonPressed;
  final void Function(int oldIndex, int newIndex) onPoolReorder;

  FixtureTypesViewModel({
    required this.fixtureTypeVms,
    required this.showAllFixtureTypes,
    required this.onShowAllFixtureTypesChanged,
    required this.tabIndex,
    required this.onTabChanged,
    required this.itemsById,
    required this.poolVms,
    required this.onCreatePoolButtonPressed,
    required this.onPoolReorder,
  });
}

class FixtureTypeViewModel extends ModelCollectionMember {
  @override
  String get uid => type.uid;

  final int qty;
  final FixtureTypeModel type;
  final void Function(String newValue)? onShortNameChanged;
  final void Function(String newValue) onMaxPairingsChanged;
  final void Function()? onMaxPairingsOverrideUnset;

  FixtureTypeViewModel({
    required this.type,
    required this.qty,
    required this.onMaxPairingsChanged,
    this.onShortNameChanged,
    this.onMaxPairingsOverrideUnset,
  });
}

class FixtureTypePoolViewModel {
  final FixtureTypePoolModel pool;
  final List<FixtureTypePoolEntryViewModel> childVms;
  final void Function(List<String> ids) onAddFixturesToPool;
  final void Function(String newValue) onNameChanged;
  final void Function() onPoolDeleted;

  FixtureTypePoolViewModel({
    required this.pool,
    required this.childVms,
    required this.onAddFixturesToPool,
    required this.onNameChanged,
    required this.onPoolDeleted,
  });
}

class FixtureTypePoolEntryViewModel {
  final FixtureTypePoolEntryModel entry;
  final FixtureTypeViewModel fixtureType;
  final void Function(String newValue) onQtyChanged;
  final void Function() onRemoveFixturePressed;

  FixtureTypePoolEntryViewModel({
    required this.entry,
    required this.onQtyChanged,
    required this.fixtureType,
    required this.onRemoveFixturePressed,
  });
}
