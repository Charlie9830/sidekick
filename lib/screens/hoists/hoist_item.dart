import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/widgets/hover_region.dart';

class HoistItem extends StatelessWidget {
  final bool assigned;
  final String name;
  final void Function(String newValue) onNameChanged;
  final void Function() onDelete;
  final int reorderableIndex;
  final bool selected;

  const HoistItem({
    super.key,
    required this.reorderableIndex,
    required this.name,
    required this.onDelete,
    required this.onNameChanged,
    required this.assigned,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return HoverRegionBuilder(builder: (context, isHovering) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        color: selected ? Theme.of(context).colorScheme.accent : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 148,
              child: EditableTextField(
                style: Theme.of(context)
                    .typography
                    .mono
                    .copyWith(color: assigned ? Colors.gray : null),
                value: name,
                hintText: 'Hoist name...',
                onChanged: onNameChanged,
              ),
            ),
            const Spacer(),
            if (isHovering) ...[
              IconButton.ghost(
                icon: const Icon(Icons.delete),
                size: ButtonSize.small,
                onPressed: onDelete,
              ),
              ReorderableDragStartListener(
                index: reorderableIndex,
                child: const SizedBox(
                  width: 32,
                  child: Center(
                      child: Icon(
                    Icons.drag_handle,
                  )),
                ),
              ),
            ]
          ],
        ),
      );
    });
  }
}
