import 'package:material_ui/material_ui.dart' show Icons;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/fixture_type_cabling_override.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/widgets/cabling_overrides_editor.dart';

class LocationCablingSettingsViewModel {
  final LocationModel location;

  /// The fixture types patched into the location, whose cabling can be
  /// overridden.
  final List<FixtureTypeModel> fixtureTypes;
  final void Function(bool value) onSetBreakAtTrussJoins;
  final void Function(String typeId, FixtureTypeCablingOverride override)
  onCablingChanged;

  LocationCablingSettingsViewModel({
    required this.location,
    required this.fixtureTypes,
    required this.onSetBreakAtTrussJoins,
    required this.onCablingChanged,
  });
}

/// Popover content editing one location's breakout cabling settings.
///
/// Changes apply immediately, so the cable view and quantities update
/// behind it.
class LocationCablingSettings extends StatelessWidget {
  final LocationCablingSettingsViewModel vm;

  const LocationCablingSettings({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final location = vm.location;
    final theme = Theme.of(context);

    return SurfaceCard(
      child: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${location.name} Cabling',
                    style: theme.typography.large,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SimpleTooltip(
                  message: 'Close',
                  child: IconButton.ghost(
                    size: ButtonSize.small,
                    icon: const Icon(Icons.close),
                    onPressed: () => closeOverlay(context),
                  ),
                ),
              ],
            ),
            Checkbox(
              state: location.breakAtTrussJoins
                  ? CheckboxState.checked
                  : CheckboxState.unchecked,
              onChanged: (state) =>
                  vm.onSetBreakAtTrussJoins(state == CheckboxState.checked),
              trailing: const Text('Break cables at truss joins'),
            ),
            if (vm.fixtureTypes.isEmpty)
              Text(
                'No fixtures in this location.',
                style: theme.typography.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: CablingOverridesEditor(
                  fixtureTypes: vm.fixtureTypes,
                  overrides: location.overrides,
                  onChanged: vm.onCablingChanged,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
