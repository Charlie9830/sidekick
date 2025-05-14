import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class FixtureTableViewModel {
  List<FixtureTableRowViewModel> rowVms;
  final Set<String> selectedFixtureIds;
  final void Function() onSetSequenceButtonPressed;
  final bool? hasSelections;
  final void Function(Set<String> ids) onSelectedFixturesChanged;
  final void Function() onSelectAllFixtures;
  final void Function(String startUid, String endUid, bool isAdditive)
      onRangeSelectFixtures;

  FixtureTableViewModel({
    required this.selectedFixtureIds,
    required this.rowVms,
    required this.onSetSequenceButtonPressed,
    required this.hasSelections,
    required this.onSelectedFixturesChanged,
    required this.onSelectAllFixtures,
    required this.onRangeSelectFixtures,
  });
}

abstract class FixtureTableRowViewModel
    with DiffComparable
    implements ModelCollectionMember {}

class FixtureRowDividerVM extends FixtureTableRowViewModel {
  final String title;
  final String locationId;
  final void Function() onSelectFixtures;

  @override
  String get uid => locationId;

  FixtureRowDividerVM({
    required this.title,
    required this.locationId,
    required this.onSelectFixtures,
  });

  @override
  Map<PropertyDeltaName, Object> getDiffValues() {
    return {
      PropertyDeltaName.locationName: title,
    };
  }
}

class FixtureViewModel extends FixtureTableRowViewModel {
  final bool selected;
  @override
  final String uid;
  final int sequence;
  final int fid;
  final String type;
  final String location;
  final String address;
  final String powerPatch;
  final bool hasSequenceNumberBreak;
  final bool hasInvalidSequenceNumber;
  final String mode;

  FixtureViewModel({
    this.selected = false,
    this.uid = '',
    this.sequence = 0,
    this.fid = 0,
    this.type = '',
    this.location = '',
    this.address = '',
    this.powerPatch = '',
    this.mode = '',
    this.hasSequenceNumberBreak = false,
    this.hasInvalidSequenceNumber = false,
  });

  @override
  Map<PropertyDeltaName, Object> getDiffValues() {
    return {
      PropertyDeltaName.fixtureId: fid,
      PropertyDeltaName.sequenceNumber: sequence,
      PropertyDeltaName.fixtureType: type,
      PropertyDeltaName.locationName: location,
      PropertyDeltaName.address: address,
      PropertyDeltaName.powerPatch: powerPatch,
      PropertyDeltaName.mode: mode,
    };
  }
}
