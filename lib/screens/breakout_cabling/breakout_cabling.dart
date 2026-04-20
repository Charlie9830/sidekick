import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/breakout_cabling/cable_qty_spreadsheet.dart';
import 'package:sidekick/screens/breakout_cabling/cable_view.dart';
import 'package:sidekick/screens/breakout_cabling/sidebar.dart';
import 'package:sidekick/three_panel_scaffold.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

class BreakoutCabling extends StatelessWidget {
  final BreakoutCablingViewModel vm;

  const BreakoutCabling({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return ThreePanelScaffold(
      toolbar: const SizedBox(),
      sidebar: SizedBox(
        width: 300,
        child: Sidebar(vm: vm),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: CableView(
              vm: vm.cableViewVm,
            ),
          ),
          Expanded(
              flex: 1,
              child: CableQtySpreadsheet(
                locationVms: vm.locationVms,
                selectedLocationId: vm.selectedLocationId,
              ))
        ],
      ),
    );
  }
}
