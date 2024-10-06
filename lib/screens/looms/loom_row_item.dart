import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/looms/editable_text_field.dart';
import 'package:sidekick/view_models/loom_screen_item_view_model.dart';

class LoomRowItem extends StatelessWidget {
  final LoomViewModel loomVm;
  final List<Widget> children;
  const LoomRowItem({
    super.key,
    required this.loomVm,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
            padding: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 400,
                      child: EditableTextField(
                        onChanged: loomVm.onNameChanged,
                        value: loomVm.loom.name,
                        hintText: 'Name',
                      ),
                    ),
                    if (loomVm.loom.type.type == LoomType.permanent)
                      const SizedBox(
                        height: 36,
                        child: Chip(
                          label: Text('Permanent'),
                          backgroundColor: Colors.blueGrey,
                          labelPadding: EdgeInsets.all(0),
                        ),
                      )
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: EditableTextField(
                        value: loomVm.loom.type.length.toStringAsFixed(0),
                        onChanged: loomVm.onLengthChanged,
                        suffix: 'm',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                        loomVm.loom.type.permanentComposition.isEmpty
                            ? 'Custom'
                            : loomVm.loom.type.permanentComposition,
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                )
              ],
            )),

        // Children
        if (children.isEmpty)
          const Text(
            'Empty',
          ),

        // Child Items
        ...children,
      ],
    );
  }
}
