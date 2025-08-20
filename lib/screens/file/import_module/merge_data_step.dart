import 'package:flutter/material.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/screens/file/import_module/raw_location_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class MergeDataStep extends StatelessWidget {
  final Map<String, String> locationMapping;
  final Map<String, LocationModel> existingLocations;
  final Map<String, RawLocationModel> incomingLocations;
  final void Function(Map<String, String> mapping) onLocationMappingUpdated;

  const MergeDataStep({
    required this.locationMapping,
    required this.existingLocations,
    required this.incomingLocations,
    required this.onLocationMappingUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double rightSidebarWidth = 300;
    final assignedExistingLocationIds = locationMapping.values.toSet();
    return DragProxyController(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Incoming Locations',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                SizedBox(
                    width: rightSidebarWidth,
                    child: Text('Existing Locations',
                        style: Theme.of(context).textTheme.labelLarge))
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: ListView(
                    children: incomingLocations.values.map((incoming) {
                      final existingLocation = existingLocations[
                          locationMapping[incoming.generatedId]];
                      return _MatcherRow(
                          incoming: incoming,
                          existing: existingLocation,
                          onLocationLanded: (existingLocation) {
                            final otherAssignments = locationMapping.entries
                                .where((entry) =>
                                    entry.value == existingLocation.uid)
                                .map((entry) => entry.key)
                                .toSet();

                            onLocationMappingUpdated(
                                Map<String, String>.from(locationMapping)
                                  ..removeWhere((key, value) =>
                                      otherAssignments.contains(key))
                                  ..addAll({
                                    incoming.generatedId: existingLocation.uid,
                                  }));
                          },
                          onClearAssignment: () {
                            onLocationMappingUpdated(
                                Map<String, String>.from(locationMapping)
                                  ..remove(incoming..generatedId));
                          });
                    }).toList(),
                  )),
                  const VerticalDivider(width: 48),
                  SizedBox(
                      width: rightSidebarWidth,
                      child: ListView(
                        children: existingLocations.values
                            .map((existingLocation) => _ExistingLocation(
                                  value: existingLocation,
                                  isAssigned: assignedExistingLocationIds
                                      .contains(existingLocation.uid),
                                ))
                            .toList(),
                      ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExistingLocation extends StatelessWidget {
  final LocationModel value;
  final bool isAssigned;
  final bool isBeingDraggedOver;
  final void Function()? onClearAssignment;

  const _ExistingLocation({
    super.key,
    required this.value,
    required this.isAssigned,
    this.isBeingDraggedOver = false,
    this.onClearAssignment,
  });

  @override
  Widget build(BuildContext context) {
    final dragContents = Card(
      color: isBeingDraggedOver
          ? Colors.blueGrey.shade500
          : Colors.blueGrey.shade900,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HoverRegionBuilder(builder: (context, isHovering) {
          return Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(value.name),
              const Spacer(),
              if (isHovering && onClearAssignment != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: onClearAssignment,
                ),
              switch (isAssigned) {
                true =>
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                false => const Icon(Icons.highlight_remove,
                    color: Colors.amber, size: 16)
              }
            ],
          );
        }),
      ),
    );

    return DraggableProxy<LocationDragData>(
        data: LocationDragData(value),
        feedback: SizedBox(
          width: 200,
          child: dragContents,
        ),
        child: dragContents);
  }
}

class LocationDragData {
  final LocationModel value;

  LocationDragData(this.value);
}

class _MatcherRow extends StatelessWidget {
  final RawLocationModel incoming;
  final LocationModel? existing;
  final void Function(LocationModel location) onLocationLanded;
  final void Function()? onClearAssignment;

  const _MatcherRow({
    super.key,
    required this.incoming,
    required this.existing,
    required this.onLocationLanded,
    this.onClearAssignment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                  child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(incoming.name),
                ],
              )),
              Expanded(
                  child: DragTargetProxy<LocationDragData>(
                      onWillAcceptWithDetails: (_) => true,
                      onAcceptWithDetails: (details) =>
                          onLocationLanded(details.data.value),
                      builder: (context, candidateData, rejectedData) {
                        if (existing != null) {
                          return _ExistingLocation(
                              isBeingDraggedOver: candidateData.isNotEmpty,
                              value: existing!,
                              isAssigned: true,
                              onClearAssignment: onClearAssignment);
                        }

                        return Card(
                          color: candidateData.isEmpty
                              ? Colors.blueGrey.shade800
                              : Colors.blueGrey.shade500,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            alignment: Alignment.centerLeft,
                            child: Text('Unassigned',
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                        );
                      }))
            ],
          ),
        ),
      ),
    );
  }
}
