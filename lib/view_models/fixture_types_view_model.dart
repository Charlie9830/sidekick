import 'package:sidekick/redux/models/fixture_type_model.dart';

class FixtureTypesViewModel {
  final List<FixtureTypeViewModel> itemVms;
  final void Function(bool newValue) onShowAllFixtureTypesChanged;
  final bool showAllFixtureTypes;

  FixtureTypesViewModel({
    required this.itemVms,
    required this.showAllFixtureTypes,
    required this.onShowAllFixtureTypesChanged,
  });
}

class FixtureTypeViewModel {
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
