import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class PowerPatchViewModel {
  final List<PowerPatchRowViewModel> rows;
  final String balanceTolerancePercent;
  final int maxSequenceBreak;
  final String selectedMultiOutlet;
  final List<FeedLoadViewModel> feedLoadings;
  final PhaseLoad totalPhaseLoad;
  final void Function() onToggleFeedsSidebarButtonPressed;
  final bool isFeedsDrawerOpen;

  final void Function(String uid) onAddSpareOutlet;
  final void Function(String uid) onDeleteSpareOutlet;
  final void Function(String newValue) onBalanceToleranceChanged;
  final void Function(String newValue) onMaxSequenceBreakChanged;
  final void Function(String uid) onMultiOutletPressed;

  PowerPatchViewModel({
    required this.selectedMultiOutlet,
    required this.rows,
    required this.feedLoadings,
    required this.balanceTolerancePercent,
    required this.onAddSpareOutlet,
    required this.onDeleteSpareOutlet,
    required this.onBalanceToleranceChanged,
    required this.onMaxSequenceBreakChanged,
    required this.maxSequenceBreak,
    required this.onMultiOutletPressed,
    required this.totalPhaseLoad,
    required this.onToggleFeedsSidebarButtonPressed,
    required this.isFeedsDrawerOpen,
  });
}

class FeedLoadViewModel {
  final PhaseLoad load;
  final PowerFeedModel feed;

  FeedLoadViewModel({
    required this.load,
    required this.feed,
  });
}

abstract class PowerPatchRowViewModel
    with DiffComparable
    implements ModelCollectionMember {}

class LocationRowViewModel extends PowerPatchRowViewModel {
  final LocationModel location;
  final int multiCount;
  final void Function() onSettingsButtonPressed;

  LocationRowViewModel({
    required this.location,
    required this.multiCount,
    required this.onSettingsButtonPressed,
  });

  @override
  String get uid => location.uid;

  @override
  Map<PropertyDeltaName, Object> getDiffValues() {
    return {
      PropertyDeltaName.locationName: location.name,
      PropertyDeltaName.multiCount: multiCount,
    };
  }
}

class MultiOutletRowViewModel extends PowerPatchRowViewModel {
  final PowerMultiOutletModel multiOutlet;
  final List<PowerOutletVM> childOutlets;

  MultiOutletRowViewModel(this.multiOutlet, this.childOutlets);

  @override
  String get uid => multiOutlet.uid;

  @override
  Map<PropertyDeltaName, Object> getDiffValues() {
    return {
      PropertyDeltaName.multiName: multiOutlet.name,
      PropertyDeltaName.desiredSpareCircuits: multiOutlet.desiredSpareCircuits,
    };
  }
}

class PowerOutletVM with DiffComparable {
  final PowerOutletModel outlet;
  final List<FixtureOutletVM> fixtureVms;
  final String poolName;

  PowerOutletVM({
    required this.outlet,
    required this.fixtureVms,
    required this.poolName,
  });

  @override
  Map<PropertyDeltaName, Object> getDiffValues() {
    return {
      PropertyDeltaName.patchedFixtureIds: outlet.fixtureIds.join('-'),
      PropertyDeltaName.fixtureType:
          fixtureVms.map((vm) => vm.type).toSet().firstOrNull?.uid ?? '',
      PropertyDeltaName.load: outlet.load,
    };
  }
}

class FixtureOutletVM {
  final FixtureModel fixture;
  final FixtureTypeModel type;

  FixtureOutletVM({
    required this.fixture,
    required this.type,
  });
}
