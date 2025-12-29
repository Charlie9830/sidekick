import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/power_patch/power_outlet_table.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

class MultiOutletRow extends StatelessWidget {
  final MultiOutletRowViewModel vm;
  final PropertyDeltaSet? propertyDeltas;
  final List<OutletDelta>? outletDeltas;
  final bool selected;
  final void Function(String uid)? onAddSpareOutlet;
  final void Function(String uid)? onDeleteSpareOutlet;

  const MultiOutletRow({
    super.key,
    required this.vm,
    this.selected = false,
    this.onAddSpareOutlet,
    this.onDeleteSpareOutlet,
    this.outletDeltas,
    this.propertyDeltas,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.electric_bolt, color: Colors.yellow, size: 20),
              const SizedBox(width: 8),
              DiffStateOverlay(
                diff: propertyDeltas?.lookup(PropertyDeltaName.multiName),
                child: Text(
                  vm.multiOutlet.name,
                  style: Theme.of(context).typography.large,
                ),
              ),
              const Spacer(),
              if (vm.multiOutlet.desiredSpareCircuits > 0 ||
                  propertyDeltas != null)
                Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: DiffStateOverlay(
                      diff: propertyDeltas
                          ?.lookup(PropertyDeltaName.desiredSpareCircuits),
                      child: Avatar(
                        backgroundColor: Colors.slate,
                        initials:
                            vm.multiOutlet.desiredSpareCircuits.toString(),
                        size: 24,
                      ),
                    )),
              IconButton.ghost(
                icon: const Icon(Icons.playlist_add),
                onPressed: vm.multiOutlet.desiredSpareCircuits < 6 &&
                        propertyDeltas == null
                    ? () => onAddSpareOutlet?.call(vm.multiOutlet.uid)
                    : null,
              ),
              IconButton.ghost(
                icon: const Icon(Icons.playlist_remove),
                onPressed: vm.multiOutlet.desiredSpareCircuits > 0 &&
                        propertyDeltas == null
                    ? () => onDeleteSpareOutlet?.call(vm.multiOutlet.uid)
                    : null,
              ),
            ],
          ),
          OutletTable(outletVM: vm.childOutlets, outletDeltas: outletDeltas),
        ],
      ),
    );
  }
}
