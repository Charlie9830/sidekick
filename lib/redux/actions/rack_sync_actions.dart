import 'package:sidekick/redux/models/data_rack_model.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';

class SetDataRacks {
  final Map<String, DataRackModel> racks;

  SetDataRacks(this.racks);
}

class SetSelectedRacksTabIndex {
  final int value;

  SetSelectedRacksTabIndex(this.value);
}

class ToggleFeedsDrawer {}

class SetPowerFeeds {
  final Map<String, PowerFeedModel> powerFeeds;

  SetPowerFeeds({required this.powerFeeds});
}

class SetPowerFeedsAndPowerRacks {
  final Map<String, PowerFeedModel> powerFeeds;
  final Map<String, PowerRackModel> racks;

  SetPowerFeedsAndPowerRacks({required this.powerFeeds, required this.racks});
}

class SetPowerRacks {
  final Map<String, PowerRackModel> racks;

  SetPowerRacks(this.racks);
}

class UpdatePowerRackName {
  final String rackId;
  final String newValue;

  UpdatePowerRackName(this.rackId, this.newValue);
}

class UpdatePowerRackNote {
  final String rackId;
  final String newValue;

  UpdatePowerRackNote(this.rackId, this.newValue);
}

class UpdateDataRackName {
  final String rackId;
  final String newValue;

  UpdateDataRackName(this.rackId, this.newValue);
}

class UpdateDataRackNote {
  final String rackId;
  final String newValue;

  UpdateDataRackNote(this.rackId, this.newValue);
}
