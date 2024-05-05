import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class PowerPatchRowViewModel {
  final PowerOutletModel outlet;
  final PowerMultiOutletModel multiOutlet;
  final LocationModel location;

  PowerPatchRowViewModel({
    required this.outlet,
    required this.multiOutlet,
    required this.location,
  });
}
