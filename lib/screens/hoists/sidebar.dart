import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/hoists/hoist_item.dart';
import 'package:sidekick/screens/hoists/hoist_location_item.dart';
import 'package:sidekick/slotted_list/attempt2.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';

const double _kSidebarWidth = 360;

class Sidebar extends StatelessWidget {
  final HoistsViewModel viewModel;
  const Sidebar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kSidebarWidth,
      child: Card(
        child: ListView.builder(
          itemCount: viewModel.sidebarItems.length,
          itemBuilder: (context, index) {
            final item = viewModel.sidebarItems[index];

            return HoistLocationItem(
                vm: item.locationVm,
                associatedHoistIds: item.associatedHoistIds);
          },
        ),
      ),
    );
  }
}
