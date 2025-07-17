import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/location_override_model.dart';
import 'package:sidekick/screens/fixture_types/fixture_type_data_table.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';
import 'package:sidekick/widgets/property_field.dart';

class LocationOverridesDialog extends StatefulWidget {
  final Map<String, LocationModel> locations;
  final Map<String, FixtureModel> fixtures;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final String initialLocationId;
  final int globalMaxSequenceBreak;

  const LocationOverridesDialog({
    super.key,
    required this.locations,
    this.initialLocationId = '',
    required this.fixtures,
    required this.fixtureTypes,
    required this.globalMaxSequenceBreak,
  });

  @override
  State<LocationOverridesDialog> createState() =>
      _LocationOverridesDialogState();
}

class _LocationOverridesDialogState extends State<LocationOverridesDialog> {
  late String _selectedLocationId;
  late Map<String, LocationModel> _locations;
  _ClipboardContents? _clipboard;
  late Map<String, _LocationFixtureQty> _fixtureQtyLookup;

  @override
  void initState() {
    _selectedLocationId = widget.initialLocationId;
    _locations = Map<String, LocationModel>.from(widget.locations)
      ..removeWhere((key, value) => value.isHybrid == true);

    _fixtureQtyLookup = _buildFixtureQtyLookup();

    super.initState();
  }

  Map<String, _LocationFixtureQty> _buildFixtureQtyLookup() {
    return Map<String, _LocationFixtureQty>.fromEntries(widget.fixtures.values
        .groupListsBy((fixture) => fixture.locationId)
        .entries
        .map((entry) {
      final locationId = entry.key;
      final fixtures = entry.value;

      // Create a map of <String, int> which represents <FixtureTypeID, qty of Fixtures with that Fixture type ID>.
      final fixtureQtysByTypeId = fixtures.fold<Map<String, int>>(
          <String, int>{},
          (map, current) => map
            ..update(
              current.typeId,
              (value) =>
                  value +
                  1, // TypeId already exists in map. So iterate the existing value.
              ifAbsent: () =>
                  1, // TypeId doesn't exist in map, so create an entry starting at 1.
            ));

      return MapEntry(
        locationId,
        _LocationFixtureQty(fixtureQtysByTypeId),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    final locationsList = _locations.values.toList();
    final selectedLocation = _locations[_selectedLocationId];

    final overrideViewModels = selectedLocation != null
        ? _getOverrideViewModels(
            location: selectedLocation,
            fixtureQtyLookup: _fixtureQtyLookup,
            associatedFixtureTypes: _getAssociatedFixtureTypes(
              fixtures: widget.fixtures,
              fixtureTypes: widget.fixtureTypes,
              locationId: _selectedLocationId,
            ))
        : <_FixtureOverrideViewModel>[];

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop()),
          title: const Text('Adjust Patch Settings'),
          actions: [
            TextButton(
              child: const Text('Save'),
              onPressed: () => Navigator.of(context).pop(_locations),
            )
          ],
        ),
        body: Builder(builder: (scaffoldContext) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar
                SizedBox(
                  width: 300,
                  child: Card(
                      child: ListView.builder(
                    itemCount: locationsList.length,
                    itemBuilder: (context, index) {
                      final location = locationsList[index];

                      return HoverRegionBuilder(builder: (context, isHovering) {
                        return ListTile(
                          title: Text(location.name),
                          selected: location.uid == _selectedLocationId,
                          dense: true,
                          onTap: () => setState(
                              () => _selectedLocationId = location.uid),
                          trailing: _clipboard != null &&
                                  (isHovering ||
                                      location.uid == _selectedLocationId)
                              ? SizedBox(
                                  width: 84,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Tooltip(
                                        message: _clipboard != null
                                            ? 'Paste settings from ${_clipboard!.sourceLocationName}.'
                                            : '',
                                        child: IconButton(
                                          icon: const Icon(Icons.paste),
                                          iconSize: 16,
                                          onPressed: _clipboard == null
                                              ? null
                                              : () =>
                                                  _handlePaste(location.uid),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        );
                      });
                    },
                  )),
                ),

                // Content
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(selectedLocation?.name ?? 'Location',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 124,
                            child: PropertyField(
                              textAlign: TextAlign.center,
                              label: 'Max Piggyback Break',
                              value: selectedLocation
                                      ?.overrides.maxSequenceBreak.value
                                      ?.toString() ??
                                  widget.globalMaxSequenceBreak.toString(),
                              onBlur: _handleMaxSequenceBreakChanged,
                            ),
                          ),
                          if (selectedLocation
                                  ?.overrides.maxSequenceBreak.value !=
                              null)
                            Tooltip(
                              message: 'Reset override',
                              child: IconButton(
                                icon: const Icon(Icons.clear),
                                iconSize: 16,
                                color: Theme.of(context).colorScheme.tertiary,
                                onPressed: _handleMaxSequenceBreakUnset,
                              ),
                            ),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            label: const Text('Copy'),
                            icon: const Icon(Icons.copy),
                            onPressed: selectedLocation == null
                                ? null
                                : () {
                                    setState(() {
                                      _clipboard = _ClipboardContents(
                                          sourceLocationName:
                                              selectedLocation.name,
                                          content: selectedLocation.overrides
                                              .copyWith());
                                    });
                                  },
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            label: const Text('Paste'),
                            icon: const Icon(Icons.paste),
                            onPressed: _clipboard != null
                                ? () => _handlePaste(_selectedLocationId)
                                : null,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FixtureOverrides(
                      fixtureOverrides: overrideViewModels,
                    ),
                  ],
                )),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _handlePaste(String locationId) {
    final location = _locations[locationId];

    if (location == null || _clipboard == null) {
      return;
    }

    setState(() {
      _locations = Map<String, LocationModel>.from(_locations)
        ..update(
          location.uid,
          (existing) => existing.copyWith(
            overrides: existing.overrides.copyWith(
              maxSequenceBreak: _clipboard!.content.maxSequenceBreak,
              maxPairings:
                  Map<String, int>.from(_clipboard!.content.maxPairings),
            ),
          ),
        );
    });
  }

  void _handleMaxSequenceBreakUnset() {
    final location = _locations[_selectedLocationId];

    if (location == null) {
      return;
    }

    setState(() {
      _locations = Map<String, LocationModel>.from(_locations)
        ..update(
          location.uid,
          (existing) => existing.copyWith(
            overrides: existing.overrides.copyWith(
              maxSequenceBreak: const OptionalInt.unset(),
            ),
          ),
        );
    });
  }

  void _handleFixtureMaxPairingsChanged(String typeId, String value) {
    if (typeId.isEmpty || widget.fixtureTypes.keys.contains(typeId) == false) {
      return;
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return;
    }

    final location = _locations[_selectedLocationId];
    if (location == null) {
      return;
    }

    setState(() {
      _locations = Map<String, LocationModel>.from(_locations)
        ..update(
            location.uid,
            (existing) => existing.copyWith(
                overrides: existing.overrides.copyWith(
                    maxPairings:
                        Map<String, int>.from(existing.overrides.maxPairings)
                          ..addAll({
                            typeId: parsed,
                          }))));
    });
  }

  void _handleMaxSequenceBreakChanged(String value) {
    final parsed = int.tryParse(value.trim());

    if (parsed == null) {
      return;
    }

    final location = _locations[_selectedLocationId];

    if (location == null) {
      return;
    }

    setState(() {
      _locations = Map<String, LocationModel>.from(_locations)
        ..update(
            location.uid,
            (existing) => existing.copyWith(
                    overrides: existing.overrides.copyWith(
                  maxSequenceBreak: OptionalInt(parsed),
                )));
    });
  }

  Map<String, FixtureTypeModel> _getAssociatedFixtureTypes({
    required Map<String, FixtureModel> fixtures,
    required Map<String, FixtureTypeModel> fixtureTypes,
    required String locationId,
  }) {
    if (locationId.isEmpty) {
      return const {};
    }

    return fixtures.values
        .where((fixture) => fixture.locationId == locationId)
        .map((fixture) => fixture.typeId)
        .toSet()
        .map((fixtureTypeId) => fixtureTypes[fixtureTypeId])
        .nonNulls
        .toModelMap();
  }

  List<_FixtureOverrideViewModel> _getOverrideViewModels({
    required LocationModel location,
    required Map<String, FixtureTypeModel> associatedFixtureTypes,
    required Map<String, _LocationFixtureQty> fixtureQtyLookup,
  }) {
    return associatedFixtureTypes.values
        .map((fixtureType) => _FixtureOverrideViewModel(
            fixtureType: fixtureType,
            typeCountInLocation: fixtureQtyLookup[location.uid]
                    ?.qtysByFixtureTypeId[fixtureType.uid] ??
                0,
            maxPairings: location.overrides.maxPairings[fixtureType.uid],
            onMaxPairingsChanged: _handleFixtureMaxPairingsChanged,
            onMaxPairingsUnset:
                location.overrides.maxPairings.containsKey(fixtureType.uid)
                    ? () => _handleFixtureMaxPairingsOverrideUnset(
                        location.uid, fixtureType.uid)
                    : null))
        .toList();
  }

  void _handleFixtureMaxPairingsOverrideUnset(
      String locationId, String fixtureTypeId) {
    if (fixtureTypeId.isEmpty) {
      return;
    }

    final location = _locations[locationId];
    if (location == null) {
      return;
    }

    setState(() {
      _locations = Map<String, LocationModel>.from(_locations)
        ..update(
            location.uid,
            (existing) => existing.copyWith(
                overrides: existing.overrides.copyWith(
                    maxPairings:
                        Map<String, int>.from(existing.overrides.maxPairings)
                          ..remove(fixtureTypeId))));
    });
  }
}

class _FixtureOverrideViewModel {
  final FixtureTypeModel fixtureType;
  final int? maxPairings;
  final void Function(String fixtureTypeId, String value) onMaxPairingsChanged;
  final void Function()? onMaxPairingsUnset;
  final int typeCountInLocation;

  _FixtureOverrideViewModel({
    required this.fixtureType,
    required this.maxPairings,
    required this.onMaxPairingsChanged,
    this.onMaxPairingsUnset,
    required this.typeCountInLocation,
  });
}

class _FixtureOverrides extends StatelessWidget {
  const _FixtureOverrides({
    required this.fixtureOverrides,
  });

  final List<_FixtureOverrideViewModel> fixtureOverrides;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: FixtureTypeDataTable(
      items: fixtureOverrides
          .map((override) => FixtureTypeViewModel(
                qty: override.typeCountInLocation,
                type: override.fixtureType.copyWith(
                    maxPiggybacks: override
                        .maxPairings), // Override the max Piggybacks value if we have an active override.
                onMaxPairingsChanged: (value) => override.onMaxPairingsChanged(
                    override.fixtureType.uid, value),
                onMaxPairingsOverrideUnset: override.onMaxPairingsUnset,
              ))
          .toList(),
    ));
  }
}

class _ClipboardContents {
  final String sourceLocationName;
  final LocationOverrideModel content;

  _ClipboardContents({
    required this.sourceLocationName,
    required this.content,
  });
}

class _LocationFixtureQty {
  final Map<String, int> qtysByFixtureTypeId;

  _LocationFixtureQty(this.qtysByFixtureTypeId);
}
