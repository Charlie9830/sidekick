import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';
import 'package:sidekick/redux/models/power_system_model.dart';

class RacksViewModel {
  final List<RackScreenItemBase> powerItemVms;

  RacksViewModel({
    required this.powerItemVms,
  });
}

sealed class RackScreenItemBase {}

class PowerRackItem extends RackScreenItemBase {
  final PowerRackModel rack;
  final List<PowerOutletItem> children;

  PowerRackItem({
    required this.rack,
    required this.children,
  });
}

class PowerSystemItem extends RackScreenItemBase {
  final PowerSystemModel system;
  final List<LocationModel> locations;

  PowerSystemItem({
    required this.system,
    required this.locations,
  });
}

class PowerOutletItem {
  final int index;
  final bool assigned;
  final String outletName;
  final String locationName;

  PowerOutletItem({
    required this.index,
    required this.assigned,
    required this.outletName,
    required this.locationName,
  });
}
