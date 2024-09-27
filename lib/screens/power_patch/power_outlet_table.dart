import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/screens/power_patch/phase_icon.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class OutletTable extends StatelessWidget {
  final List<PowerOutletVM> outletVM;

  const OutletTable({
    required this.outletVM,
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
          children: outletVM
              .map((vm) => TableRow(children: [
                    // Multi Patch
                    Center(child: Text(vm.outlet.multiPatch.toString())),
                    // Phase
                    PhaseIcon(phaseNumber: vm.outlet.phase),
                    // Fixture Name
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(vm.fixtureVm
                          .map((fixtureVm) => fixtureVm.type.shortName)
                          .toSet()
                          .join(", ")),
                    ),
                    // Fixture Ids
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(vm.fixtureVm
                          .map((fixtureVM) => fixtureVM.fixture.fid)
                          .join(", ")),
                    ),
                    // Load
                    Center(
                        child: vm.outlet.load == 0
                            ? const SizedBox()
                            : Text('${vm.outlet.load.toStringAsFixed(1)}A')),
                  ]))
              .toList()),
    );
  }
}
