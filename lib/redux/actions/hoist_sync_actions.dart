import 'package:sidekick/redux/models/hoist_controller_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

class SetHoistsAndControllers {
  final Map<String, HoistControllerModel> hoistControllers;
  final Map<String, HoistModel> hoists;

  SetHoistsAndControllers({
    required this.hoistControllers,
    required this.hoists,
  });
}

class SetHoistControllers {
  final Map<String, HoistControllerModel> value;

  SetHoistControllers(this.value);
}

class SetSelectedHoistOutlets {
  final Set<String> value;

  SetSelectedHoistOutlets(this.value);
}

class UpdateHoistControllerName {
  final String hoistId;
  final String value;

  UpdateHoistControllerName({required this.hoistId, required this.value});
}

class UpdateHoistControllerWayCount {
  final String hoistId;
  final int value;

  UpdateHoistControllerWayCount({required this.hoistId, required this.value});
}

class AppendSelectedHoistChannelId {
  final String value;

  AppendSelectedHoistChannelId(this.value);
}

class SetSelectedHoistChannelIds {
  final Set<String> value;

  SetSelectedHoistChannelIds(this.value);
}

class SetHoists {
  final Map<String, HoistModel> value;

  SetHoists(this.value);
}

class UpdateHoistNote {
  final String id;
  final String value;

  UpdateHoistNote(this.id, this.value);
}

class SetHoistMultis {
  final Map<String, HoistMultiModel> multis;

  SetHoistMultis(this.multis);
}
