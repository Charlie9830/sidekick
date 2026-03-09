import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/widgets/hover_region.dart';

class PowerMultiItem extends StatelessWidget {
  final bool assigned;
  final String name;
  final bool selected;

  const PowerMultiItem({
    super.key,
    required this.name,
    required this.assigned,
    required this.selected,
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
      );
    });
  }
}
