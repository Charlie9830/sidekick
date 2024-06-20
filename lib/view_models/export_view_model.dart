import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class ExportViewModel {
  final List<PowerOutletModel> outlets;
  final Map<String, LocationModel> locations;
  final void Function() onExportButtonPressed;

  ExportViewModel({
    required this.outlets,
    required this.locations,
    required this.onExportButtonPressed,
  });
}
