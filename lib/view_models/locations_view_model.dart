import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/location_model.dart';

class LocationsViewModel {
  final List<LocationItemViewModel> itemVms;
  final void Function(String location, String newValue) onMultiPrefixChanged;
  final void Function(String locationId, String newValue) onLocationNameChanged;
  final void Function(String locationId, Color color) onLocationColorChanged;

  LocationsViewModel({
    required this.itemVms,
    required this.onMultiPrefixChanged,
    required this.onLocationNameChanged,
    required this.onLocationColorChanged,
  });
}

class LocationItemViewModel {
  final LocationModel location;
  final int powerMultiCount;
  final int dataMultiCount;
  final int dataPatchCount;

  LocationItemViewModel({
    required this.location,
    required this.powerMultiCount,
    required this.dataMultiCount,
    required this.dataPatchCount,
  });
}
