import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as mat;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/power_patch/phase_icon.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class OutletTable extends StatelessWidget {
  final List<PowerOutletVM> outletVM;
  final List<OutletDelta>? outletDeltas;

  const OutletTable({
    required this.outletVM,
    required this.outletDeltas,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: mat.Table(
          border: TableBorder.symmetric(
              inside: BorderSide(color: Theme.of(context).colorScheme.border)),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FixedColumnWidth(36), // Multi Patch
            1: FixedColumnWidth(64), // Phase
            2: FlexColumnWidth(1), // Fixture naem
            3: FlexColumnWidth(3), // Fixture IDs
            4: FixedColumnWidth(72), // Load
          },
          children: outletVM.mapIndexed((index, vm) {
            final currentDelta = outletDeltas?.elementAtOrNull(index);

            return mat.TableRow(children: [
              // Multi Patch
              Center(
                  child: Text(vm.outlet.multiPatch.toString(),
                          style: Theme.of(context).typography.mono)
                      .muted),
              // Phase
              PhaseIcon(phaseNumber: vm.outlet.phase),
              // Fixture Name
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: DiffStateOverlay(
                  diff: currentDelta?.properties
                      .lookup(PropertyDeltaName.fixtureType),
                  child: Text(vm.fixtureVms
                      .map((fixtureVm) => fixtureVm.type.shortName)
                      .toSet()
                      .join(", ")),
                ),
              ),
              // Fixture Ids
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: DiffStateOverlay(
                  diff: currentDelta?.properties
                      .lookup(PropertyDeltaName.patchedFixtureIds),
                  child: Text(
                      vm.fixtureVms
                          .map((fixtureVM) => fixtureVM.fixture.fid)
                          .join(", "),
                      style: Theme.of(context).typography.mono),
                ),
              ),
              // Load
              DiffStateOverlay(
                diff: currentDelta?.properties.lookup(PropertyDeltaName.load),
                child: Center(
                    child: vm.outlet.load == 0
                        ? const SizedBox()
                        : Text('${vm.outlet.load.toStringAsFixed(1)}A').muted),
              ),
            ]);
          }).toList()),
    );
  }
}
