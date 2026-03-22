import 'package:sidekick/redux/models/data_rack_model.dart';
import 'package:sidekick/redux/models/hoist_controller_model.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_rack_model.dart';

enum ExportErrorLevel {
  warning,
  critical,
}

enum ErrorScope {
  power,
  data,
  hoist,
}

class ExportErrorModel {
  final ExportErrorLevel level;
  final String name;
  final String message;
  final ErrorScope scope;

  ExportErrorModel({
    required this.level,
    required this.name,
    required this.message,
    required this.scope,
  });

  factory ExportErrorModel.unassignedHoist(String hoistName) {
    return ExportErrorModel(
        scope: ErrorScope.hoist,
        level: ExportErrorLevel.warning,
        name: 'Unassigned Hoist',
        message: "$hoistName has not been assigned a rack outlet");
  }

  factory ExportErrorModel.unassignedPowerMulti(String multiName) {
    return ExportErrorModel(
        scope: ErrorScope.power,
        level: ExportErrorLevel.warning,
        name: 'Unassigned Power Multi',
        message: "$multiName has not been assigned a rack outlet");
  }

  factory ExportErrorModel.unassignedDataPatch(String patchName) {
    return ExportErrorModel(
        scope: ErrorScope.data,
        level: ExportErrorLevel.warning,
        name: 'Unassigned Data Outlet',
        message: "$patchName has not been assigned a rack outlet");
  }

  factory ExportErrorModel.overflowingPowerRack(PowerRackModel rack) {
    return ExportErrorModel(
        scope: ErrorScope.power,
        level: ExportErrorLevel.critical,
        name: 'Overflowing Power Rack',
        message: "${rack.name} has too many outlets assigned to it");
  }

  factory ExportErrorModel.overflowingDataRack(DataRackModel rack) {
    return ExportErrorModel(
        scope: ErrorScope.data,
        level: ExportErrorLevel.critical,
        name: 'Overflowing Data Rack',
        message: "${rack.name} has too many data outlets assigned to it");
  }

  factory ExportErrorModel.overflowingHoistController(
      HoistControllerModel controller) {
    return ExportErrorModel(
        scope: ErrorScope.hoist,
        level: ExportErrorLevel.warning,
        name: 'Overflowing Hoist Controller',
        message: "${controller.name} has too many hoists assigned to it");
  }

  factory ExportErrorModel.powerFeedNearingCapacity(
      PowerFeedModel feed, double load) {
    return ExportErrorModel(
      scope: ErrorScope.power,
      level: ExportErrorLevel.warning,
      name: 'Power Feed near capacity',
      message: '${feed.name} is loaded at over 80% capacity',
    );
  }

  factory ExportErrorModel.powerFeedOverloaded(
      PowerFeedModel feed, double load) {
    return ExportErrorModel(
      scope: ErrorScope.power,
      level: ExportErrorLevel.critical,
      name: 'Overloaded Power Feed',
      message:
          '${feed.name} is overloaded. Capacity: ${feed.capacity}  Load: ${load.ceil()}',
    );
  }

  ExportErrorModel copyWith({
    ExportErrorLevel? level,
    String? name,
    String? message,
    ErrorScope? scope,
  }) {
    return ExportErrorModel(
      level: level ?? this.level,
      name: name ?? this.name,
      message: message ?? this.message,
      scope: scope ?? this.scope,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExportErrorModel &&
        other.scope == scope &&
        other.level == level &&
        other.message == message &&
        other.name == name;
  }

  @override
  int get hashCode =>
      scope.hashCode ^ level.hashCode ^ name.hashCode ^ message.hashCode;
}
