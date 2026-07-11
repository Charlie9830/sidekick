import 'package:flutter/material.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/cable_qty_diffing_item_view_model.dart';

/// Shows how the breakout cable quantities differ from the comparison project,
/// grouped by location. Only locations with at least one changed cable group are
/// listed.
class CableQtyDiffing extends StatelessWidget {
  final List<CableQtyDiffingItemViewModel> itemVms;
  const CableQtyDiffing({required this.itemVms, super.key});

  @override
  Widget build(BuildContext context) {
    final changedItems = itemVms
        .where((item) => item.hasChanges)
        .toList(growable: false);

    if (changedItems.isEmpty) {
      return const Center(child: Text('No cable quantity changes.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemCount: changedItems.length,
      itemBuilder: (context, index) =>
          _LocationSection(item: changedItems[index]),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final CableQtyDiffingItemViewModel item;
  const _LocationSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final changedDeltas =
        item.deltas
            .where((delta) => delta.state != DiffState.unchanged)
            .toList()
          ..sort(
            (a, b) => a.group.label.compareTo(b.group.label),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.locationName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...changedDeltas.map((delta) => _DeltaRow(delta: delta)),
      ],
    );
  }
}

class _DeltaRow extends StatelessWidget {
  final CableQtyDelta delta;
  const _DeltaRow({required this.delta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 240, child: Text(delta.group.label)),
          Text(
            '${delta.originalQty}  →  ${delta.currentQty}',
            style: TextStyle(
              color: _colorFor(delta.state),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(DiffState state) => switch (state) {
    DiffState.added => SidekickColors.diffAdded,
    DiffState.deleted => SidekickColors.diffDeleted,
    DiffState.changed => SidekickColors.diffChanged,
    DiffState.unchanged => Colors.grey,
  };
}
