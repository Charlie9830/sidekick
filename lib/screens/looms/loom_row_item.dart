import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/looms/loom_header.dart';
import 'package:sidekick/view_models/loom_view_model.dart';

class LoomRowItem extends StatelessWidget {
  final LoomViewModel loomVm;
  final List<Widget> children;
  final PropertyDeltaSet? deltas;
  final int reorderableListViewIndex;

  const LoomRowItem({
    super.key,
    required this.loomVm,
    required this.children,
    required this.reorderableListViewIndex,
    this.deltas,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LoomHeader(
              loomVm: loomVm,
              reorderableListViewIndex: reorderableListViewIndex,
              deltas: deltas,
            ),
          ),

          // Child Items
          ...children,
        ],
      ),
    );
  }
}
