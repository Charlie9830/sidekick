import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_system_model.dart';
import 'package:sidekick/view_models/power_system_view_model.dart';

class LocationsViewModel {
  final List<LocationItemViewModel> itemVms;
  final void Function(String location, String newValue) onMultiPrefixChanged;
  final void Function(String locationId, LabelColorModel color)
      onLocationColorChanged;
  final void Function(String locationId, String newValue)
      onLocationDelimiterChanged;
  final List<PowerSystemViewModel> powerSystemVms;

  LocationsViewModel({
    required this.itemVms,
    required this.onMultiPrefixChanged,
    required this.onLocationColorChanged,
    required this.onLocationDelimiterChanged,
    required this.powerSystemVms,
  });
}

class LocationItemViewModel {
  final LocationModel location;
  final int powerMultiCount;
  final int dataMultiCount;
  final int dataPatchCount;
  final int motorCount;
  final List<String> otherLocationNames;
  final void Function() onDelete;
  final void Function() onEditName;

  LocationItemViewModel({
    required this.location,
    required this.powerMultiCount,
    required this.dataMultiCount,
    required this.dataPatchCount,
    required this.otherLocationNames,
    required this.motorCount,
    required this.onDelete,
    required this.onEditName,
  });
}
