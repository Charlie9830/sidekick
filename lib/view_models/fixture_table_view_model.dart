class FixtureTableViewModel {
  List<FixtureTableRow> rowVms;
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

abstract class FixtureTableRow {}

class FixtureRowDividerVM extends FixtureTableRow {
  final String title;
  final String locationId;
  final void Function() onSelectFixtures;

  FixtureRowDividerVM({
    required this.title,
    required this.locationId,
    required this.onSelectFixtures,
  });
}

class FixtureViewModel extends FixtureTableRow {
  final bool selected;
  final String uid;
  final int sequence;
  final int fid;
  final String type;
  final String location;
  final String address;
  final String powerMulti;
  final int powerPatch;
  final String dataMulti;
  final String dataPatch;
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
    this.powerMulti = '',
    this.powerPatch = 0,
    this.dataMulti = '',
    this.dataPatch = '',
    this.mode = '',
    this.hasSequenceNumberBreak = false,
    this.hasInvalidSequenceNumber = false,
  });
}
