import 'package:flutter/material.dart' hide TableRow;
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
      FixtureViewModel row => _buildTableRow(row, rangeSelectFixtureStartId),
      _ => const SizedBox(),
    };
  }

  TableRow _buildTableRow(
      FixtureViewModel row, String rangeSelectStartFixtureId) {
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
            child: Text(row.fid.toString())),
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
            child: Text(row.address)),
        DiffStateOverlay(
            diff: deltas?.lookup(PropertyDeltaName.powerPatch),
            child: Text(row.powerPatch)),
      ],
    );
  }

  Widget _buildDivider(BuildContext context, FixtureRowDividerVM dividerVM) {
    return InkWell(
      onTap: () => dividerVM.onSelectFixtures(),
      child: Column(
        children: [
          const Divider(height: 0),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Icon(Icons.location_on,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(dividerVM.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Theme.of(context).colorScheme.primary))
            ]),
          ),
          const SizedBox(height: 24),
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
            ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: hasInvalidSequenceNumber ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold)
            : Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Colors.grey));
  }
}
