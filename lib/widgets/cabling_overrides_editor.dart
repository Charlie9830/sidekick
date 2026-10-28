import 'package:material_ui/material_ui.dart' show Icons;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/cabling/cable_stock.dart';
import 'package:sidekick/cable_graph/cabling/connector_cable_map.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_type_cabling_override.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_override_model.dart';
import 'package:sidekick/screens/looms/cable_type_select.dart';
import 'package:sidekick/simple_tooltip.dart';

/// Per fixture type breakout cabling overrides for a single location.
///
/// Shared by the location overrides dialog and the breakout cabling page.
class CablingOverridesEditor extends StatelessWidget {
  final List<FixtureTypeModel> fixtureTypes;
  final LocationOverrideModel overrides;
  final void Function(String typeId, FixtureTypeCablingOverride override)
  onChanged;

  const CablingOverridesEditor({
    super.key,
    required this.fixtureTypes,
    required this.overrides,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: fixtureTypes.length,
      itemBuilder: (context, index) {
        final type = fixtureTypes[index];
        final override = overrides.getCabling(type.uid);

        return Padding(
          key: ValueKey(type.uid),
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            spacing: 16,
            children: [
              Expanded(child: Text(type.name)),
              Expanded(
                flex: 4,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _CableOverrideSelect(
                      label: 'Power',
                      value: override.power,
                      options: fixtureCableTypes(CableSignal.power),
                      onChanged: (cable) =>
                          onChanged(type.uid, override.withPower(cable)),
                    ),
                    _CableOverrideSelect(
                      label: 'Data',
                      value: override.data,
                      options: fixtureCableTypes(CableSignal.data),
                      onChanged: (cable) =>
                          onChanged(type.uid, override.withData(cable)),
                    ),
                    _OrientationSelect(
                      value: override.orientation,
                      onChanged: (orientation) => onChanged(
                        type.uid,
                        override.withOrientation(orientation),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Picks the cable for one signal of a fixture type, or none to keep the
/// cable its GDTF wiring describes.
class _CableOverrideSelect extends StatelessWidget {
  final String label;
  final CableType? value;
  final List<CableType> options;
  final void Function(CableType? cable) onChanged;

  const _CableOverrideSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(label, style: Theme.of(context).typography.small),
        SizedBox(
          width: 160,
          child: Select<CableType>(
            value: value,
            placeholder: const Text('From GDTF'),
            onChanged: onChanged,
            itemBuilder: (context, item) =>
                Text(humanFriendlyCableTypeName(item)),
            popup: SelectPopup(
              items: SelectItemList(
                children: [
                  for (final option in options)
                    SelectItemButton(
                      value: option,
                      child: Text(humanFriendlyCableTypeName(option)),
                    ),
                ],
              ),
            ).call,
          ),
        ),
        SimpleTooltip(
          message: 'Reset override',
          child: IconButton.ghost(
            size: ButtonSize.small,
            icon: const Icon(Icons.clear),
            onPressed: value == null ? null : () => onChanged(null),
          ),
        ),
      ],
    );
  }
}

/// Picks how chains running against the flow are cabled.
class _OrientationSelect extends StatelessWidget {
  final ChainOrientation value;
  final void Function(ChainOrientation orientation) onChanged;

  const _OrientationSelect({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SimpleTooltip(
      message:
          'For chains whose connectors run against the patch order, such as '
          'bars with their input at the far end from the header.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text('Orientation', style: Theme.of(context).typography.small),
          SizedBox(
            width: 190,
            child: Select<ChainOrientation>(
              value: value,
              onChanged: (orientation) =>
                  orientation == null ? null : onChanged(orientation),
              itemBuilder: (context, item) => Text(item.label),
              popup: SelectPopup(
                items: SelectItemList(
                  children: [
                    for (final option in ChainOrientation.values)
                      SelectItemButton(
                        value: option,
                        child: Text(option.label),
                      ),
                  ],
                ),
              ).call,
            ),
          ),
        ],
      ),
    );
  }
}
