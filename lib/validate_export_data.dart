import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/export_error_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

List<ExportErrorModel> validateExportData(FixtureState state) {
  return [
    ..._validatePowerPatch(state),
    ..._validateDataPatch(state),
    ..._validateHoistPatch(state),
  ];
}

List<ExportErrorModel> _validateHoistPatch(FixtureState state) {
  return {
    ..._processUnassignedHoists(state),
    ..._processOverflowingHoistControllers(state),
  }.toList();
}

List<ExportErrorModel> _validateDataPatch(FixtureState state) {
  return {
    ..._processUnassignedDataPatches(state),
    ..._processOverflowingDataRacks(state),
  }.toList();
}

List<ExportErrorModel> _validatePowerPatch(FixtureState state) {
  return {
    ..._processUnassignedPowerMultis(state),
    ..._processOverflowingPowerRacks(state),
    ..._processPowerFeeds(state),
  }.toList();
}

List<ExportErrorModel> _processUnassignedHoists(FixtureState state) {
  return state.hoists.values
      .map((outlet) => outlet.parentController.isAssigned
          ? null
          : ExportErrorModel.unassignedHoist(outlet.name))
      .nonNulls
      .toList();
}

List<ExportErrorModel> _processPowerFeeds(FixtureState state) {
  final feedLoads = state.powerMultiOutlets.values
      .groupListsBy((outlet) =>
          state.powerRacks[outlet.parentRack.rackId]?.powerFeedId ?? '')
      .map((feedId, outlets) => MapEntry(
          feedId,
          outlets
              .map((outlet) => outlet.draw)
              .reduce((accum, current) => accum.addedWith(current))
              .hottest))
      .map(
          (feedId, totalLoad) => MapEntry(state.powerFeeds[feedId], totalLoad));

  return feedLoads.entries
      .map((entry) {
        final feed = entry.key;
        final load = entry.value;

        if (feed == null) {
          return null;
        }

        if (load > feed.capacity) {
          return ExportErrorModel.powerFeedOverloaded(feed, load);
        }

        if (load / feed.capacity >= 0.80) {
          return ExportErrorModel.powerFeedNearingCapacity(feed, load);
        }
      })
      .nonNulls
      .toList();
}

List<ExportErrorModel> _processUnassignedPowerMultis(FixtureState state) {
  return state.powerMultiOutlets.values
      .map((outlet) => outlet.parentRack.isAssigned
          ? null
          : ExportErrorModel.unassignedPowerMulti(outlet.name))
      .nonNulls
      .toList();
}

List<ExportErrorModel> _processUnassignedDataPatches(FixtureState state) {
  return state.dataPatches.values
      .map((outlet) => outlet.parentRack.isAssigned
          ? null
          : ExportErrorModel.unassignedDataPatch(outlet.name))
      .nonNulls
      .toList();
}

List<ExportErrorModel> _processOverflowingPowerRacks(FixtureState state) {
  final powerMultiOutletsByRackId = state.powerMultiOutlets.values
      .groupListsBy((outlet) => outlet.parentRack.rackId);

  return powerMultiOutletsByRackId.entries
      .map((entry) {
        final rackId = entry.key;
        final outlets = entry.value;

        final rack = state.powerRacks[rackId];

        if (rack == null) {
          return null;
        }

        final rackType = state.powerRackTypes[rack.typeId];

        if (rackType == null) {
          return null;
        }

        if (PowerMultiOutletModel.getHighestChannelNumber(outlets) >
            rackType.multiOutletCount) {
          return ExportErrorModel.overflowingPowerRack(rack);
        }

        return null;
      })
      .nonNulls
      .toList();
}

List<ExportErrorModel> _processOverflowingDataRacks(FixtureState state) {
  final dataPatchesByRackId = state.dataPatches.values
      .groupListsBy((outlet) => outlet.parentRack.rackId);

  return dataPatchesByRackId.entries
      .map((entry) {
        final rackId = entry.key;
        final outlets = entry.value;

        final rack = state.dataRacks[rackId];

        if (rack == null) {
          return null;
        }

        final rackType = state.dataRackTypes[rack.typeId];

        if (rackType == null) {
          return null;
        }

        if (DataPatchModel.getHighestChannelNumber(outlets) >
            rackType.outletCount) {
          return ExportErrorModel.overflowingDataRack(rack);
        }

        return null;
      })
      .nonNulls
      .toList();
}

List<ExportErrorModel> _processOverflowingHoistControllers(FixtureState state) {
  final hoistsByRackId = state.hoists.values
      .groupListsBy((outlet) => outlet.parentController.controllerId);

  return hoistsByRackId.entries
      .map((entry) {
        final rackId = entry.key;
        final outlets = entry.value;

        final controller = state.hoistControllers[rackId];

        if (controller == null) {
          return null;
        }

        if (HoistModel.getHighestChannelNumber(outlets) > controller.ways) {
          return ExportErrorModel.overflowingHoistController(controller);
        }

        return null;
      })
      .nonNulls
      .toList();
}
