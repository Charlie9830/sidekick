import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/location_override_model.dart';

class BalancerLocationModel {
  final String uid;
  final LocationOverrideModel overrides;

  BalancerLocationModel({
    required this.uid,
    required this.overrides,
  });

  factory BalancerLocationModel.fromLocation(LocationModel location) {
    return BalancerLocationModel(
        uid: location.uid, overrides: location.overrides);
  }
}
