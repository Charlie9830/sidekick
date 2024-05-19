import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/screens/power_patch/phase_icon.dart';

class OutletTable extends StatelessWidget {
  final List<PowerOutletModel> outlets;

  const OutletTable({
    required this.outlets,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
          border: TableBorder.symmetric(
              inside: BorderSide(color: Theme.of(context).dividerColor)),
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
                            : Text('${outlet.child.amps.toStringAsFixed(1)}A')),
                  ]))
              .toList()),
    );
  }
}
