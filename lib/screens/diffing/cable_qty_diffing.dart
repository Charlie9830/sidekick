import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:sidekick/view_models/cable_qty_diffing_item_view_model.dart';

/// Shows how the breakout cable quantities differ from the comparison project,
/// grouped by location. Only locations with at least one changed cable group are
/// listed.
class CableQtyDiffing extends StatelessWidget {
  final List<CableQtyDiffingItemViewModel> itemVms;
  const CableQtyDiffing({required this.itemVms, super.key});

  @override
  Widget build(BuildContext context) {
    final changedItems =
        itemVms.where((item) => item.hasChanges).toList(growable: false);

    if (changedItems.isEmpty) {
      return const Center(child: Text('No cable quantity changes.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemCount: changedItems.length,
      itemBuilder: (context, index) => _LocationSection(item: changedItems[index]),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final CableQtyDiffingItemViewModel item;
  const _LocationSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final changedDeltas = item.deltas
        .where((delta) => delta.state != DiffState.unchanged)
        .toList()
      ..sort((a, b) => _formatGroup(a.group).compareTo(_formatGroup(b.group)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.locationName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
          SizedBox(
            width: 240,
            child: Text(_formatGroup(delta.group)),
          ),
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

String _formatGroup(CableQtyGroup group) {
  final lengthText = group.length.remainder(1) == 0
      ? '${group.length.toStringAsFixed(0)}m'
      : '${group.length.toStringAsFixed(1)}m';

  final typeSlug = switch (group.type) {
    CableType.unknown => 'Unknown',
    CableType.socapex => 'Soca',
    CableType.wieland6way => '6way',
    CableType.sneak => 'Sneak',
    CableType.dmx => 'DMX',
    CableType.hoist => 'Motor Cable',
    CableType.hoistMulti => 'Motor Multi',
    CableType.au10a => '10A Ext',
    CableType.true1 => 'True1 Ext',
    CableType.socapexToAu10ALampHeader => 'Soca AU10A Header',
    CableType.socapexToTrue1LampHeader => 'Socapex True1 Header',
    CableType.wieland6WayLampHeader => '6way AU10A Header',
    CableType.sneakLampHeader => 'SS Lamp Header',
    CableType.hoistMultiLampHeader => 'Motor Multi Lamp Header',
    CableType.hoistMultiRackHeader => 'Motor Multi Rack Header',
  };

  const headerTypes = {
    CableType.socapexToAu10ALampHeader,
    CableType.socapexToTrue1LampHeader,
    CableType.sneakLampHeader,
    CableType.hoistMultiRackHeader,
    CableType.hoistMultiLampHeader,
    CableType.wieland6WayLampHeader,
  };

  return headerTypes.contains(group.type) ? typeSlug : '$lengthText $typeSlug';
}
