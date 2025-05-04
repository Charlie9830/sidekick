import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/screens/file/import_module/incoming_fixture_item_view_model.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';

typedef CellBuilder = Widget Function(
    BuildContext context, CellBuilderCallback callback);
typedef CellBuilderCallback = Widget Function(
    BuildContext context, int columnIndex);

class ViewDataStep extends StatelessWidget {
  final bool showDiffOverlays;
  final List<IncomingFixtureItemViewModel> vms;
  const ViewDataStep({
    super.key,
    required this.vms,
    this.showDiffOverlays = true,
  });

  @override
  Widget build(BuildContext context) {
    final headerTextStyle = Theme.of(context).textTheme.titleSmall;

    Widget wrapColumn(Widget child, {Widget? overhead}) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            overhead ?? const SizedBox(height: 24),
            child,
            const SizedBox(height: 8),
          ],
        );

    Widget overhead(String text) => Text(
          text,
          overflow: TextOverflow.visible,
          maxLines: 1,
          style: Theme.of(context).textTheme.titleMedium,
        );

    final headers = {
      0: wrapColumn(Text('Fix #', style: headerTextStyle),
          overhead: overhead("Incoming")),
      1: wrapColumn(Text('Type', style: headerTextStyle)),
      2: wrapColumn(Text('Mode', style: headerTextStyle)),
      3: wrapColumn(Text('DMX', style: headerTextStyle)),
      4: wrapColumn(Text('Location', style: headerTextStyle)),
      5: const VerticalDivider(),
      6: wrapColumn(Text('Fix #', style: headerTextStyle),
          overhead: overhead("Existing")),
      7: wrapColumn(Text('Type', style: headerTextStyle)),
      8: wrapColumn(Text('Mode', style: headerTextStyle)),
      9: wrapColumn(Text('DMX', style: headerTextStyle)),
      10: wrapColumn(Text('Location', style: headerTextStyle)),
    };

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!,
        child: TableView.builder(
            headerHeight: 64,
            headerBuilder: (context, builder) =>
                builder(context, (context, column) => headers[column]!),
            columns: const [
              TableColumn(
                width: 100,
              ),
              TableColumn(
                width: 164,
              ),
              TableColumn(
                width: 164,
              ),
              TableColumn(
                width: 100,
              ),
              TableColumn(
                width: 124,
              ),

              // Centerline Divider
              TableColumn(
                width: 16,
              ),

              TableColumn(
                width: 84,
              ),
              TableColumn(
                width: 164,
              ),
              TableColumn(
                width: 164,
              ),
              TableColumn(
                width: 100,
              ),
              TableColumn(
                width: 200,
              ),
            ],
            rowCount: vms.length,
            rowHeight: 48,
            rowBuilder: (context, rowIndex, cellBuilder) {
              final vm = vms[rowIndex];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Horizontal Divider
                  SizedBox(
                    height: 8,
                    child: rowIndex == 0 ? const SizedBox() : const Divider(),
                  ),

                  // Content
                  Expanded(
                    child: _buildRow(context, vm.incomingFixture,
                        vm.existingFixture, cellBuilder, showDiffOverlays),
                  ),
                ],
              );
            }),
      ),
    );
  }

  Widget _buildRow(
      BuildContext context,
      FixtureViewModel? incoming,
      FixtureViewModel? existing,
      CellBuilder cellBuilder,
      bool showDiffOverlays) {
    final overallDiffState = showDiffOverlays
        ? switch ((existing, incoming)) {
            (null, FixtureViewModel()) => DiffState.added,
            (FixtureViewModel(), null) => DiffState.deleted,
            _ => DiffState.unchanged,
          }
        : DiffState.unchanged;

    final incomingFixtureId = incoming?.fid.toString() ?? '';
    final existingFixtureId = existing?.fid.toString() ?? '';

    final incomingFixtureType = incoming?.type ?? '';
    final existingFixtureType = existing?.type ?? '';

    final incomingMode = incoming?.mode ?? '';
    final existingMode = existing?.mode ?? '';

    final incomingAddress = incoming?.address ?? '';
    final existingAddress = existing?.address ?? '';

    final incomingLocation = incoming?.location ?? '';
    final existingLocation = existing?.location ?? '';

    final cells = <int, Widget>{
      // Incoming Fixture
      0: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(
            incomingFixtureId, existingFixtureId, overallDiffState),
        child: _Cell(incomingFixtureId),
      ),
      1: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(
            incomingFixtureType, existingFixtureType, overallDiffState),
        child: _Cell(incomingFixtureType),
      ),
      2: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(incomingMode, existingMode, overallDiffState),
        child: _Cell(incomingMode),
      ),
      3: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(
            incomingAddress, existingAddress, overallDiffState),
        child: _Cell(incomingAddress),
      ),
      4: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(
            incomingLocation, existingLocation, overallDiffState),
        child: _Cell(incomingLocation),
      ),

      // Divider
      5: const VerticalDivider(),

      // Existing Fixture
      6: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(
            incomingFixtureId, existingFixtureId, overallDiffState),
        child: _Cell(existingFixtureId),
      ),
      7: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(
            incomingFixtureType, existingFixtureType, overallDiffState),
        child: _Cell(existingFixtureType),
      ),
      8: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(incomingMode, existingMode, overallDiffState),
        child: _Cell(existingMode),
      ),
      9: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(
            incomingAddress, existingAddress, overallDiffState),
        child: _Cell(existingAddress),
      ),
      10: DiffStateOverlay(
        enabled: showDiffOverlays,
        diff: _computeDiffState(
            incomingLocation, existingLocation, overallDiffState),
        child: _Cell(existingLocation),
      ),
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
            child: cellBuilder(
                context,
                (context, index) => Column(
                      children: [
                        Expanded(child: cells[index]!),
                      ],
                    ))),
      ],
    );
  }

  DiffState _computeDiffState(
      String valueA, String valueB, DiffState overallDiffState) {
    if (overallDiffState == DiffState.added) {
      return DiffState.added;
    }

    if (overallDiffState == DiffState.deleted) {
      return DiffState.deleted;
    }

    return valueA == valueB ? DiffState.unchanged : DiffState.changed;
  }
}

class _Cell extends StatelessWidget {
  final String value;
  const _Cell(this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        overflow: TextOverflow.fade,
      ),
    );
  }
}
