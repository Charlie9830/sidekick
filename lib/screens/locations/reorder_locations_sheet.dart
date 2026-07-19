import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/screens/locations/hybrid_tag.dart';
import 'package:sidekick/screens/locations/multi_color_chit.dart';
import 'package:sidekick/screens/locations/rigging_only_tag.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

/// Modal sheet for batching a location reorder. Drags only mutate local
/// state; Apply pops the final ordered uid list, Cancel/dismiss pops null.
class ReorderLocationsSheet extends StatefulWidget {
  final List<LocationModel> locations;

  const ReorderLocationsSheet({super.key, required this.locations});

  @override
  State<ReorderLocationsSheet> createState() => _ReorderLocationsSheetState();
}

class _ReorderLocationsSheetState extends State<ReorderLocationsSheet> {
  late final List<LocationModel> _orderedLocations;

  @override
  void initState() {
    _orderedLocations = widget.locations.toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locationNamesById = {
      for (final location in widget.locations) location.uid: location.name,
    };

    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reorder Locations').medium,
            Expanded(
              child: ReorderableList(
                padding: EdgeInsets.zero,
                itemCount: _orderedLocations.length,
                itemBuilder: (context, index) => _LocationRow(
                  key: Key(_orderedLocations[index].uid),
                  index: index,
                  location: _orderedLocations[index],
                  locationNamesById: locationNamesById,
                ),
                onReorderItem: _handleReorder,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button.ghost(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                IconButton.secondary(
                  icon: const Icon(
                    Icons.check_circle,
                    color: SidekickColors.success,
                  ),
                  trailing: const Text('Apply'),
                  onPressed: () => Navigator.of(context).pop(
                    _orderedLocations.map((location) => location.uid).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    // onReorderItem already adjusts newIndex for the removed item.
    setState(() {
      final item = _orderedLocations.removeAt(oldIndex);
      _orderedLocations.insert(newIndex, item);
    });
  }
}

class _LocationRow extends StatelessWidget {
  final int index;
  final LocationModel location;
  final Map<String, String> locationNamesById;

  const _LocationRow({
    super.key,
    required this.index,
    required this.location,
    required this.locationNamesById,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        spacing: 8,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          MultiColorChit(height: 18, value: location.color),
          Expanded(child: Text(location.name, overflow: TextOverflow.ellipsis)),
          if (location.isRiggingOnlyLocation) const RiggingOnlyTag(),
          if (location.isHybrid)
            HybridTag(
              otherLocationNames: location.hybridIds
                  .map((id) => locationNamesById[id])
                  .nonNulls
                  .toList(),
            ),
        ],
      ),
    );
  }
}
