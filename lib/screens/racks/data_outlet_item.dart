import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/widgets/hover_region.dart';

class DataOutletItem extends StatelessWidget {
  final bool assigned;
  final String name;
  final bool selected;
  final int universe;
  final String parentMultiName;

  const DataOutletItem({
    super.key,
    required this.name,
    required this.assigned,
    required this.selected,
    required this.universe,
    required this.parentMultiName,
  });

  @override
  Widget build(BuildContext context) {
    return HoverRegionBuilder(builder: (context, isHovering) {
      return ShadListItem(
        selected: selected,
        enabled: !assigned,
        leading: Icon(Icons.settings_input_svideo,
            size: 16, color: assigned ? Colors.gray : Colors.blue),
        title: Text(
          name,
          style: Theme.of(context)
              .typography
              .mono
              .copyWith(color: assigned ? Colors.gray : null),
        ),
        trailing: Row(
          children: [
            if (parentMultiName.isNotEmpty)
              Card(
                borderRadius: BorderRadius.circular(4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                filled: true,
                fillColor: Colors.neutral.shade700,
                child: Text(parentMultiName),
              ),
            SizedBox(
                width: 64,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('U$universe',
                      style: Theme.of(context).typography.mono),
                )),
          ],
        ),
      );
    });
  }
}
