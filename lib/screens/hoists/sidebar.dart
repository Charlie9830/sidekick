import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/hoists/hoist_channel_content.dart';
import 'package:sidekick/screens/hoists/hoist_item.dart';
import 'package:sidekick/screens/hoists/hoist_location_item.dart';
import 'package:sidekick/slotted_list/slotted_list.dart';
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
          itemCount: viewModel.hoistItems.length,
          itemBuilder: (context, index) {
            final item = viewModel.hoistItems[index];
            return switch (item) {
              HoistLocationViewModel vm => HoistLocationItem(vm: vm),
              HoistViewModel vm => CandidateListItem(
                  configuration: CandidateData(
                    itemId: vm.uid,
                    candidateBuilder: (context) =>
                        HoistItem(vm: vm, reorderableIndex: index),
                    candidateSelectionIndex: vm.unslottedSelectionIndex,
                  ),
                  feedbackConstraints:
                      const BoxConstraints.tightFor(width: _kSidebarWidth),
                ),
            };
          },
        ),
      ),
    );
  }
}
