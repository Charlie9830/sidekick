import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/breakout_cabling/cable_qty_spreadsheet.dart';
import 'package:sidekick/screens/breakout_cabling/cable_view.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

/// The breakout cabling page: the whole rig's cabling in the 3D view beside
/// the per-location cable quantities.
class BreakoutCabling extends StatelessWidget {
  final BreakoutCablingViewModel vm;

  const BreakoutCabling({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: CableView(vm: vm.cableViewVm)),
        Expanded(
          flex: 2,
          child: CableQtySpreadsheet(locationVms: vm.locationVms),
        ),
      ],
    );
  }
}
