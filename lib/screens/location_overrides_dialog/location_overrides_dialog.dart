import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/location_override_model.dart';
import 'package:sidekick/screens/fixture_types/fixture_type_data_table.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/titled_card.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/hover_region.dart';
import 'package:sidekick/widgets/property_field.dart';

class LocationOverridesDialog extends StatefulWidget {
  final Map<String, LocationModel> locations;
  final Map<String, FixtureModel> fixtures;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final Map<String, FixtureTypePoolModel> fixtureTypePools;
  final String initialLocationId;
  final int globalMaxSequenceBreak;

  const LocationOverridesDialog({
    super.key,
    required this.locations,
    this.initialLocationId = '',
    required this.fixtures,
    required this.fixtureTypes,
    required this.globalMaxSequenceBreak,
    required this.fixtureTypePools,
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

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop()),
          ],
          trailing: [
            PrimaryButton(
              child: const Text('Save'),
              onPressed: () => Navigator.of(context).pop(_locations),
            )
          ],
          title: const Text('Adjust Patch Settings'),
        )
      ],
      child: Builder(builder: (scaffoldContext) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar
            _Sidebar(
              locationsList: locationsList,
              selectedLocationId: _selectedLocationId,
              onLocationSelected: (id) =>
                  setState(() => _selectedLocationId = id),
              onPaste: _handlePaste,
              clipboard: _clipboard,
            ),

            // Content Zone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FloatingContentToolbar(
                      selectedLocation: selectedLocation,
                      globalMaxSequenceBreak: widget.globalMaxSequenceBreak,
                      onMaxSequenceBreakChanged: _handleMaxSequenceBreakChanged,
                      onMaxSequenceBreakUnset: _handleMaxSequenceBreakUnset,
                      onPaste: _handlePaste,
                      clipboard: _clipboard,
                      onCopyButtonPressed: (locationName, overrideContents) =>
                          setState(() => _clipboard = _ClipboardContents(
                              sourceLocationName: locationName,
                              content: overrideContents.copyWith()))),
                  const CardTitle(title: 'Types'),
                  Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: _FixtureOverrides(
                            fixtureOverrides: overrideViewModels,
                          ),
                        ),
                      )),
                  const CardTitle(title: 'Pools'),
                  Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: _PoolConfiguration(
                              pools: widget.fixtureTypePools.values.toList(),
                              enabledFixtureTypePoolIds: selectedLocation
                                      ?.overrides.enabledFixtureTypePoolIds ??
                                  {},
                              fixtureTypes: widget.fixtureTypes,
                              onPoolEnableChanged: (poolId, enabled) =>
                                  _handlePoolEnableStateChanged(
                                      selectedLocation: selectedLocation,
                                      poolId: poolId,
                                      enabled: enabled)),
                        ),
                      )),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _handlePoolEnableStateChanged({
    required LocationModel? selectedLocation,
    required String poolId,
    required bool enabled,
  }) {
    if (selectedLocation == null) {
      return;
    }

    final updatedLocations = _locations.clone()
      ..update(
        selectedLocation.uid,
        (existing) => existing.copyWith(
          overrides: existing.overrides.copyWith(
            enabledFixtureTypePoolIds: enabled == true
                ? {...existing.overrides.enabledFixtureTypePoolIds, poolId}
                : (existing.overrides.enabledFixtureTypePoolIds.toSet()
                  ..remove(poolId)),
          ),
        ),
      );

    setState(() {
      _locations = updatedLocations;
    });
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

class _FloatingContentToolbar extends StatelessWidget {
  final LocationModel? selectedLocation;
  final int globalMaxSequenceBreak;
  final void Function(String newValue) onMaxSequenceBreakChanged;
  final void Function() onMaxSequenceBreakUnset;
  final void Function(
          String locationName, LocationOverrideModel overrideContent)
      onCopyButtonPressed;
  final void Function(String locationId) onPaste;
  final _ClipboardContents? clipboard;

  const _FloatingContentToolbar({
    super.key,
    required this.selectedLocation,
    required this.globalMaxSequenceBreak,
    required this.onMaxSequenceBreakChanged,
    required this.onMaxSequenceBreakUnset,
    required this.onCopyButtonPressed,
    required this.clipboard,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(selectedLocation?.name ?? 'Location',
              style: Theme.of(context).typography.lead),
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
                  value: selectedLocation?.overrides.maxSequenceBreak.value
                          ?.toString() ??
                      globalMaxSequenceBreak.toString(),
                  onBlur: onMaxSequenceBreakChanged,
                ),
              ),
              if (selectedLocation?.overrides.maxSequenceBreak.value != null)
                SimpleTooltip(
                  message: 'Reset override',
                  child: IconButton.ghost(
                    size: ButtonSize.small,
                    icon: const Icon(Icons.clear),
                    onPressed: onMaxSequenceBreakUnset,
                  ),
                ),
              const Spacer(),
              OutlineButton(
                leading: const Icon(Icons.copy),
                onPressed: selectedLocation == null
                    ? null
                    : () => onCopyButtonPressed(
                          selectedLocation!.name,
                          selectedLocation!.overrides,
                        ),
                child: const Text('Copy'),
              ),
              const SizedBox(width: 8),
              OutlineButton(
                leading: const Icon(Icons.paste),
                onPressed: clipboard != null && selectedLocation != null
                    ? () => onPaste(selectedLocation!.uid)
                    : null,
                child: const Text('Paste'),
              )
            ],
          ),
        ),
      ],
    );
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
    return FixtureTypeDataTable(
      items: fixtureOverrides
          .map((override) => FixtureTypeViewModel(
                qty: override.typeCountInLocation,
                isMaxPairingsOverriden: override.maxPairings != null,
                type: override.fixtureType.copyWith(
                    maxPiggybacks: override
                        .maxPairings), // Override the max Piggybacks value if we have an active override.
                onMaxPairingsChanged: (value) => override.onMaxPairingsChanged(
                    override.fixtureType.uid, value),
                onMaxPairingsOverrideUnset: override.onMaxPairingsUnset,
              ))
          .toList(),
    );
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

class _Sidebar extends StatelessWidget {
  final List<LocationModel> locationsList;
  final String selectedLocationId;
  final void Function(String locationId) onLocationSelected;
  final void Function(String locationId) onPaste;
  final _ClipboardContents? clipboard;

  const _Sidebar(
      {super.key,
      required this.locationsList,
      required this.selectedLocationId,
      required this.onLocationSelected,
      required this.clipboard,
      required this.onPaste});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
          padding: EdgeInsets.zero,
          child: ListView.builder(
            itemCount: locationsList.length,
            itemBuilder: (context, index) {
              final location = locationsList[index];

              return HoverRegionBuilder(builder: (context, isHovering) {
                return ShadListItem(
                  title: Text(location.name),
                  selected: location.uid == selectedLocationId,
                  onTap: () => onLocationSelected(location.uid),
                  leading: location.overrides.hasOverrides
                      ? const Icon(Icons.check_circle,
                          size: 12, color: Colors.teal)
                      : null,
                  trailing: clipboard != null &&
                          (isHovering || location.uid == selectedLocationId)
                      ? SizedBox(
                          width: 84,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SimpleTooltip(
                                message: clipboard != null
                                    ? 'Paste settings from ${clipboard!.sourceLocationName}.'
                                    : '',
                                child: IconButton.ghost(
                                  icon: const Icon(Icons.paste),
                                  size: ButtonSize.small,
                                  onPressed: clipboard == null
                                      ? null
                                      : () => onPaste(location.uid),
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
    );
  }
}

class _PoolConfiguration extends StatelessWidget {
  final List<FixtureTypePoolModel> pools;
  final Map<String, FixtureTypeModel> fixtureTypes;
  final Set<String> enabledFixtureTypePoolIds;
  final void Function(String poolId, bool enabled) onPoolEnableChanged;

  const _PoolConfiguration({
    super.key,
    required this.pools,
    required this.enabledFixtureTypePoolIds,
    required this.onPoolEnableChanged,
    required this.fixtureTypes,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: pools.length,
      itemBuilder: (context, index) {
        final pool = pools[index];

        return Row(
          children: [
            Checkbox(
              state: enabledFixtureTypePoolIds.contains(pool.uid)
                  ? CheckboxState.checked
                  : CheckboxState.unchecked,
              onChanged: (state) => onPoolEnableChanged(
                pool.uid,
                state == CheckboxState.checked ? true : false,
              ),
            ),
            const SizedBox(width: 8),
            Text(pool.name),
            const SizedBox(width: 24),
            Text(_buildChildFixtureSlug(pool, fixtureTypes),
                style: Theme.of(context).typography.thin)
          ],
        );
      },
    );
  }

  String _buildChildFixtureSlug(
      FixtureTypePoolModel pool, Map<String, FixtureTypeModel> fixtureTypes) {
    return pool.items.values
        .map((item) => '${item.qty}x ${fixtureTypes[item.typeId]?.shortName}')
        .join(', ');
  }
}
