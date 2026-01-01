import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class HoistItem extends StatelessWidget {
  final HoistViewModel vm;
  final int reorderableIndex;
  const HoistItem({
    super.key,
    required this.vm,
    required this.reorderableIndex,
  });

  @override
  Widget build(BuildContext context) {
    return HoverRegionBuilder(builder: (context, isHovering) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          height: 40,
          color: vm.selected ? Theme.of(context).colorScheme.accent : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: reorderableIndex,
                child: const SizedBox(
                  width: 32,
                  child: Center(
                      child: Icon(Icons.drag_handle,
                          color: Colors.gray, size: 20)),
                ),
              ),
              SizedBox(
                width: 148,
                child: EditableTextField(
                  style: Theme.of(context)
                      .typography
                      .mono
                      .copyWith(color: vm.assigned ? Colors.gray : null),
                  value: vm.hoist.name,
                  hintText: 'Hoist name...',
                  onChanged: vm.onNameChanged,
                ),
              ),
              const Spacer(),
              if (isHovering)
                IconButton.ghost(
                  icon: const Icon(Icons.delete),
                  size: ButtonSize.small,
                  onPressed: vm.onDelete,
                )
            ],
          ),
        ),
      );
    });
  }
}
