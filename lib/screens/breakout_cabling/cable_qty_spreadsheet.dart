import 'package:material_ui/material_ui.dart' show Icons;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/location_cabling_settings_container.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// Cable quantities per location: one column per location, one row per cable
/// type and length. Each column header carries the location's "break at truss
/// joins" toggle and a button opening its cabling settings.
class CableQtySpreadsheet extends StatelessWidget {
  final List<LocationViewModel> locationVms;

  const CableQtySpreadsheet({super.key, required this.locationVms});

  @override
  Widget build(BuildContext context) {
    final List<CableQtyGroup> allGroups = CableQtyGroup.allGroups;
    final borderColor = Theme.of(context).colorScheme.border;
    final borderSide = BorderSide(color: borderColor, width: 0.25);

    return Card(
      child: TableView.builder(
        columnCount: locationVms.length + 1,
        rowCount: allGroups.length + 1,
        columnBuilder: (index) {
          if (index == 0) {
            return const TableSpan(extent: FixedSpanExtent(124));
          }

          return TableSpan(
            foregroundDecoration: SpanDecoration(
              border: SpanBorder(leading: borderSide),
            ),
            extent: const FixedSpanExtent(32),
          );
        },
        rowBuilder: (index) {
          if (index == 0) {
            return const TableSpan(extent: FixedSpanExtent(200));
          }

          final currentType = allGroups[index - 1].type;
          final nextType = allGroups.elementAtOrNull(index)?.type;

          return TableSpan(
            extent: const FixedSpanExtent(32),
            foregroundDecoration: SpanDecoration(
              border: SpanBorder(
                leading: borderSide,
                trailing: currentType != nextType
                    ? borderSide.copyWith(width: 2)
                    : BorderSide.none,
              ),
            ),
          );
        },
        cellBuilder: (context, vic) => _cellBuilder(context, vic, allGroups),
      ),
    );
  }

  TableViewCell _cellBuilder(
    BuildContext context,
    TableVicinity vicinity,
    List<CableQtyGroup> allGroups,
  ) {
    if (vicinity.row == 0) {
      // Header Row
      return _buildHeaderCell(context, vicinity.column);
    }

    if (vicinity.column == 0) {
      return _buildCableTypeCell(context, vicinity.row, allGroups);
    }

    return _buildContentCell(context, vicinity, allGroups);
  }

  TableViewCell _buildHeaderCell(BuildContext context, int columnIndex) {
    if (columnIndex == 0) {
      return const TableViewCell(child: SizedBox());
    }
    final location = locationVms.elementAtOrNull(columnIndex - 1);
    return TableViewCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          spacing: 8,
          children: [
            if (location != null) ...[
              _EditSettingsButton(location: location.location),
              _TrussBreakToggle(locationVm: location),
            ],
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    location?.location.name ?? '',
                    style: Theme.of(context).typography.small,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableViewCell _buildCableTypeCell(
    BuildContext context,
    int rowIndex,
    List<CableQtyGroup> allGroups,
  ) {
    final cableGroup = allGroups.elementAtOrNull(rowIndex - 1);
    return TableViewCell(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          cableGroup?.label ?? '',
          style: Theme.of(context).typography.small,
        ),
      ),
    );
  }

  TableViewCell _buildContentCell(
    BuildContext context,
    TableVicinity vicinity,
    List<CableQtyGroup> allGroups,
  ) {
    final location = locationVms.elementAtOrNull(vicinity.column - 1);
    final qtyGroup = allGroups.elementAtOrNull(vicinity.row - 1);

    if (location == null || qtyGroup == null) {
      return const TableViewCell(child: Text(''));
    }

    final cellValue = location.cableQtys[qtyGroup]?.toString() ?? '';

    return TableViewCell(child: Center(child: Text(cellValue)));
  }
}

/// Column-header button opening a location's cabling settings in a popover.
class _EditSettingsButton extends StatelessWidget {
  final LocationModel location;

  const _EditSettingsButton({required this.location});

  @override
  Widget build(BuildContext context) {
    return SimpleTooltip(
      message: 'Edit ${location.name} cabling settings',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () =>
              showLocationCablingSettingsPopover(context, location.uid),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              Icons.tune,
              size: 14,
              color: Theme.of(context).colorScheme.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Column-header control signalling and toggling whether cables in a
/// location break where they cross a truss join.
///
/// The default (breaking) state is kept quiet so the eye catches the
/// exceptions: locations set to run cables through joins show a loud accent
/// badge instead.
class _TrussBreakToggle extends StatelessWidget {
  final LocationViewModel locationVm;

  const _TrussBreakToggle({required this.locationVm});

  @override
  Widget build(BuildContext context) {
    final breaks = locationVm.location.breakAtTrussJoins;

    return SimpleTooltip(
      message: breaks
          ? 'Cables break at truss joins'
          : 'Cables run through truss joins (no break)',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => locationVm.onSetBreakAtTrussJoins(!breaks),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              breaks ? Icons.content_cut : Icons.block,
              size: 12,
              color: breaks
                  ? Theme.of(context).colorScheme.mutedForeground
                  : SidekickColors.warning,
            ),
          ),
        ),
      ),
    );
  }
}
