import 'package:sidekick/redux/models/fixture_type_model.dart';

class FixtureTypesViewModel {
  final List<FixtureTypeViewModel> itemVms;
  final void Function(String id, String newValue) onShortNameChanged;
  final void Function(String id, String newValue) onMaxPairingsChanged;
  final void Function(bool newValue) onShowAllFixtureTypesChanged;
  final bool showAllFixtureTypes;

  FixtureTypesViewModel({
    required this.itemVms,
    required this.onShortNameChanged,
    required this.onMaxPairingsChanged,
    required this.showAllFixtureTypes,
    required this.onShowAllFixtureTypesChanged,
  });
}

class FixtureTypeViewModel {
  final int qty;
  final FixtureTypeModel type;

  FixtureTypeViewModel({
    required this.type,
    required this.qty,
  });
}
