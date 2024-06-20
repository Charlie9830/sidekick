import 'package:sidekick/redux/models/fixture_type_model.dart';

class FixtureTypesViewModel {
  final List<FixtureTypeViewModel> itemVms;
  final void Function(String id, String newValue) onNameChanged;
  final void Function(String id, String newValue) onShortNameChanged;
  final void Function(String id, String newValue) onMaxPairingsChanged;

  FixtureTypesViewModel({
    required this.itemVms,
    required this.onNameChanged,
    required this.onShortNameChanged,
    required this.onMaxPairingsChanged,
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
