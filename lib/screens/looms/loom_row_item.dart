import 'package:flutter/material.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/looms/cable_row_item.dart';
import 'package:sidekick/screens/looms/loom_header.dart';
import 'package:sidekick/view_models/loom_view_model.dart';

class LoomRowItem extends StatelessWidget {
  final LoomViewModel loomVm;
  final List<Widget> children;
  final Set<PropertyDelta> deltas;
  final int reorderableListViewIndex;

  const LoomRowItem({
    super.key,
    required this.loomVm,
    required this.children,
    required this.reorderableListViewIndex,
    this.deltas = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LoomHeader(
            loomVm: loomVm,
            reorderableListViewIndex: reorderableListViewIndex,
          ),

          // Child Items
          ...children,
        ],
      ),
    );
  }
}
