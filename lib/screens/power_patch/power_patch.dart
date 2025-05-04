import 'package:flutter/material.dart';
import 'package:sidekick/screens/power_patch/balance_gauge.dart';
import 'package:sidekick/screens/power_patch/location_header_trailer.dart';
import 'package:sidekick/screens/power_patch/power_outlet_table.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';
import 'package:sidekick/widgets/location_header_row.dart';
import 'package:sidekick/widgets/property_field.dart';
import 'package:sidekick/widgets/toolbar.dart';

class PowerPatch extends StatefulWidget {
  final PowerPatchViewModel vm;
  const PowerPatch({Key? key, required this.vm}) : super(key: key);

  @override
  State<PowerPatch> createState() => _PowerPatchState();
}

class _PowerPatchState extends State<PowerPatch> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant PowerPatch oldWidget) {
    if (widget.vm.rows != oldWidget.vm.rows) {}

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Toolbar(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: PropertyField(
              textAlign: TextAlign.center,
              label: 'Balance Tolerance',
              suffix: '%',
              value: widget.vm.balanceTolerancePercent,
              onBlur: widget.vm.onBalanceToleranceChanged,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
              width: 124,
              child: PropertyField(
                textAlign: TextAlign.center,
                label: 'Max Piggyback Break',
                value: widget.vm.maxSequenceBreak.toString(),
                onBlur: widget.vm.onMaxSequenceBreakChanged,
              )),
          const SizedBox(width: 16),
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.commit),
                onPressed: widget.vm.onCommit,
                label: const Text('Commit'),
              ),
              const SizedBox(width: 16),
              BalanceGauge(
                phaseALoad: widget.vm.phaseLoad.a,
                phaseBLoad: widget.vm.phaseLoad.b,
                phaseCLoad: widget.vm.phaseLoad.c,
              )
            ],
          ))
        ],
      )),
      Expanded(
        child: ListView.builder(
          itemCount: widget.vm.rows.length,
          itemBuilder: (context, index) => _buildRow(
            context,
            widget.vm.rows[index],
          ),
        ),
      )
    ]);
  }

  Widget _buildRow(BuildContext context, PowerPatchRow row) {
    return switch (row) {
      LocationRow locationRow => LocationHeaderRow(
          key: Key(locationRow.location.uid),
          location: locationRow.location,
          trailing: LocationHeaderTrailer(
            multiCount: row.multiCount,
            isLocked: locationRow.location.isPowerPatchLocked,
            onLockChanged: (value) => row.onLockChanged(value),
          ),
        ),
      MultiOutletRow outletRow => _buildMultiOutlet(context, outletRow),
      _ => const Text("Error"),
    };
  }

  Widget _buildMultiOutlet(BuildContext context, MultiOutletRow row) {
    return GestureDetector(
      onTap: () => widget.vm.onMultiOutletPressed(row.multiOutlet.uid),
      child: Card(
        color: widget.vm.selectedMultiOutlet == row.multiOutlet.uid
            ? Theme.of(context).highlightColor
            : null,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.electric_bolt,
                      color: Colors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      row.multiOutlet.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Spacer(),
                  if (row.multiOutlet.desiredSpareCircuits > 0)
                    Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          radius: 12,
                          child: Text(
                            '${row.multiOutlet.desiredSpareCircuits}',
                          ),
                        )),
                  IconButton(
                    icon: const Icon(Icons.playlist_add),
                    onPressed: row.multiOutlet.desiredSpareCircuits < 6
                        ? () => widget.vm.onAddSpareOutlet(row.multiOutlet.uid)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_remove),
                    onPressed: row.multiOutlet.desiredSpareCircuits > 0
                        ? () =>
                            widget.vm.onDeleteSpareOutlet(row.multiOutlet.uid)
                        : null,
                  ),
                ],
              ),
            ),
            OutletTable(outletVM: row.childOutlets),
          ],
        ),
      ),
    );
  }
}
