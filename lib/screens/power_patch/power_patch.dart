import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/screens/power_patch/balance_gauge.dart';
import 'package:sidekick/screens/power_patch/phase_icon.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class PowerPatch extends StatefulWidget {
  final PowerPatchViewModel vm;
  const PowerPatch({Key? key, required this.vm}) : super(key: key);

  @override
  State<PowerPatch> createState() => _PowerPatchState();
}

class _PowerPatchState extends State<PowerPatch> {
  double _phaseALoad = 0;
  double _phaseBLoad = 0;
  double _phaseCLoad = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant PowerPatch oldWidget) {
    if (widget.vm.multiOutlets != oldWidget.vm.multiOutlets) {
      final outlets = widget.vm.multiOutlets.values.flattened;

      _phaseALoad = (outlets
          .where((outlet) => outlet.phase == 1)
          .map((outlet) => outlet.child.amps)
          .fold(0, (prev, value) => prev + value));
      _phaseBLoad = (outlets
          .where((outlet) => outlet.phase == 2)
          .map((outlet) => outlet.child.amps)
          .fold(0, (prev, value) => prev + value));
      _phaseCLoad = (outlets
          .where((outlet) => outlet.phase == 3)
          .map((outlet) => outlet.child.amps)
          .fold(0, (prev, value) => prev + value));
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final multiOutlets = widget.vm.multiOutlets.keys.toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 64,
        child: Card(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.cable),
              label: const Text('Patch'),
              onPressed: widget.vm.onGeneratePatch,
            ),
            const VerticalDivider(
              indent: 8,
              endIndent: 8,
            ),
            const SizedBox(width: 16),
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
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BalanceGauge(
                    phaseALoad: _phaseALoad,
                    phaseBLoad: _phaseBLoad,
                    phaseCLoad: _phaseCLoad)
              ],
            ))
          ],
        )),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: widget.vm.multiOutlets.keys.length,
          itemBuilder: (context, index) => _buildMultiOutlet(
            context,
            multiOutlets[index],
          ),
        ),
      )
    ]);
  }

  Widget _buildMultiOutlet(
      BuildContext context, PowerMultiOutletModel multiOutlet) {
    final outlets = widget.vm.multiOutlets[multiOutlet];

    if (outlets == null) {
      return const Text("Outlets was Null");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: Key(multiOutlet.uid),
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            top: 8.0,
            bottom: 8.0,
            right: 8.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.electric_bolt, color: Colors.yellow),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  multiOutlet.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Spacer(),
              if (multiOutlet.desiredSpareCircuits > 0)
                Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      radius: 12,
                      child: Text(
                        '${multiOutlet.desiredSpareCircuits}',
                      ),
                    )),
              IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: multiOutlet.desiredSpareCircuits < 6
                    ? () => widget.vm.onAddSpareOutlet(multiOutlet.uid)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.playlist_remove),
                onPressed: multiOutlet.desiredSpareCircuits > 0
                    ? () => widget.vm.onDeleteSpareOutlet(multiOutlet.uid)
                    : null,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => widget.vm.onMultiOutletPressed(multiOutlet.uid),
          child: Card(
            color: widget.vm.selectedMultiOutlet == multiOutlet.uid
                ? Theme.of(context).highlightColor
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Table(
                  border: TableBorder.symmetric(
                      inside:
                          BorderSide(color: Theme.of(context).dividerColor)),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(36), // Multi Patch
                    1: FixedColumnWidth(64), // Phase
                    2: FlexColumnWidth(1), // Fixture naem
                    3: FlexColumnWidth(3), // Fixture IDs
                    4: FixedColumnWidth(72), // Load
                  },
                  children: outlets
                      .map((outlet) => TableRow(children: [
                            // Multi Patch
                            Center(child: Text(outlet.multiPatch.toString())),
                            // Phase
                            PhaseIcon(phaseNumber: outlet.phase),
                            // Fixture Name
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(outlet.child.fixtures
                                  .map((fixture) => fixture.type.name)
                                  .toSet()
                                  .join(", ")),
                            ),
                            // Fixture Ids
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(outlet.child.fixtures
                                  .map((fixture) => fixture.fid)
                                  .join(", ")),
                            ),
                            // Load
                            Center(
                                child: outlet.child.amps == 0
                                    ? const SizedBox()
                                    : Text(
                                        '${outlet.child.amps.toStringAsFixed(1)}A')),
                          ]))
                      .toList()),
            ),
          ),
        )
      ],
    );
  }
}
