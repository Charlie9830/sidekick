import 'package:flutter/material.dart';
import 'package:sidekick/screens/locations/rigging_only_tag.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class HoistLocationItem extends StatelessWidget {
  final HoistLocationViewModel vm;
  const HoistLocationItem({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: HoverRegionBuilder(builder: (context, isHovering) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(vm.location.name,
                  key: Key(vm.location.uid),
                  style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              if (vm.location.isRiggingOnlyLocation)
                Row(
                  children: [
                    if (isHovering)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        iconSize: 20,
                        onPressed: vm.onDeleteLocation,
                      ),
                    const RiggingOnlyTag(),
                  ],
                ),
              IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 20,
                  tooltip: 'Add Hoist',
                  visualDensity: VisualDensity.compact,
                  onPressed: vm.onAddHoistButtonPressed)
            ],
          ),
        );
      }),
    );
  }
}
