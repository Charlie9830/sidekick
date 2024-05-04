import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class LoomNamesViewModel {
  final List<PowerOutletModel> outlets;
  final Map<String, LocationModel> locations;
  final void Function(String location, String newValue) onMultiPrefixChanged;
  final void Function(LocationModel location) onCommitPowerPressed;

  LoomNamesViewModel({
    required this.outlets,
    required this.locations,
    required this.onMultiPrefixChanged,
    required this.onCommitPowerPressed,
  });
}
