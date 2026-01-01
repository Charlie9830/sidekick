import 'package:shadcn_flutter/shadcn_flutter.dart' hide TableRow;
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';
import 'package:sidekick/screens/home/table_row.dart';

class FixtureTableRow extends StatelessWidget {
  final FixtureTableRowViewModel vm;
  final String rangeSelectFixtureStartId;
  final PropertyDeltaSet? deltas;
  final void Function(bool isSelected, String id)? onSelectChanged;

  const FixtureTableRow({
    super.key,
    required this.vm,
    this.rangeSelectFixtureStartId = '',
    this.onSelectChanged,
    this.deltas,
  });

  @override
  Widget build(BuildContext context) {
    return switch (vm) {
      FixtureRowDividerVM row => _buildDivider(context, row),
      FixtureViewModel row =>
        _buildTableRow(context, row, rangeSelectFixtureStartId),
      _ => const SizedBox(),
    };
  }

  TableRow _buildTableRow(BuildContext context, FixtureViewModel row,
      String rangeSelectStartFixtureId) {
    return TableRow(
      rangeSelected: rangeSelectStartFixtureId == row.uid,
      selected: row.selected,
      onPressed: (isSelected) => onSelectChanged?.call(isSelected, row.uid),
      cells: [
        DiffStateOverlay(
          diff: deltas?.lookup(PropertyDeltaName.sequenceNumber),
          child: _SequenceNumberCell(
            value: row.sequence.toString(),
            hasInvalidSequenceNumber: row.hasInvalidSequenceNumber,
            hasSequenceNumberBreak: row.hasSequenceNumberBreak,
          ),
        ),
        DiffStateOverlay(
            diff: deltas?.lookup(PropertyDeltaName.fixtureId),
            child: Text(row.fid.toString(),
                style: Theme.of(context).typography.mono)),
        DiffStateOverlay(
            diff: deltas?.lookup(PropertyDeltaName.fixtureType),
            child: Text(row.type)),
        DiffStateOverlay(
            diff: deltas?.lookup(PropertyDeltaName.mode),
            child: Text(row.mode)),
        DiffStateOverlay(
            diff: deltas?.lookup(PropertyDeltaName.locationName),
            child: Text(row.location)),
        DiffStateOverlay(
            diff: deltas?.lookup(PropertyDeltaName.address),
            child: Text(row.address, style: Theme.of(context).typography.mono)),
        DiffStateOverlay(
            diff: deltas?.lookup(PropertyDeltaName.powerPatch),
            child:
                Text(row.powerPatch, style: Theme.of(context).typography.mono)),
      ],
    );
  }

  Widget _buildDivider(BuildContext context, FixtureRowDividerVM dividerVM) {
    return Button(
      style: const ButtonStyle.menubar(),
      onPressed: () => dividerVM.onSelectFixtures(),
      child: Column(
        children: [
          const Divider(height: 0),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              const Icon(Icons.location_on, size: 24, color: Colors.gray),
              const SizedBox(width: 8),
              Text(dividerVM.title, style: Theme.of(context).typography.xLarge)
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 0),
        ],
      ),
    );
  }
}

class _SequenceNumberCell extends StatelessWidget {
  final String value;
  final bool hasSequenceNumberBreak;
  final bool hasInvalidSequenceNumber;

  const _SequenceNumberCell({
    required this.hasInvalidSequenceNumber,
    required this.hasSequenceNumberBreak,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text(value,
        style: hasSequenceNumberBreak || hasInvalidSequenceNumber
            ? Theme.of(context).typography.small.copyWith(
                color: hasInvalidSequenceNumber ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold)
            : Theme.of(context).typography.small.copyWith(color: Colors.gray));
  }
}
