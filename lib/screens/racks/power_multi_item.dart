import 'package:shadcn_flutter/shadcn_flutter.dart';
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
                child: Text(
                  name,
                  style: Theme.of(context)
                      .typography
                      .mono
                      .copyWith(color: assigned ? Colors.gray : null),
                ),
              ),
            ]),
      );
    });
  }
}
