import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/screens/looms/cable_type_select.dart';
import 'package:sidekick/simple_tooltip.dart';

class LoomsToolbarContents extends StatelessWidget {
  final void Function() onCombineIntoMultiButtonPressed;
  final void Function() onSplitMultiButtonPressed;
  final void Function()? onDeleteSelectedCables;
  final void Function(CableType type) onDefaultPowerMultiTypeChanged;
  final void Function()? onChangePowerMultiTypeOfSelectedCables;
  final CableType defaultPowerMultiType;
  final Widget? infoTrailer;
  final bool availabilityDrawOpen;
  final void Function() onShowAvailabilityDrawPressed;

  const LoomsToolbarContents({
    super.key,
    required this.onCombineIntoMultiButtonPressed,
    required this.onSplitMultiButtonPressed,
    required this.onDeleteSelectedCables,
    required this.defaultPowerMultiType,
    required this.onDefaultPowerMultiTypeChanged,
    required this.onChangePowerMultiTypeOfSelectedCables,
    required this.availabilityDrawOpen,
    required this.onShowAvailabilityDrawPressed,
    this.infoTrailer,
  });

  @override
  Widget build(BuildContext context) {
    const Widget spacer = SizedBox(width: 8);
    return Row(
      children: [
        SimpleTooltip(
            message: 'Delete selected Cables',
            child: IconButton.destructive(
                onPressed: onDeleteSelectedCables,
                icon: const Icon(Icons.delete))),
        spacer,
        const VerticalDivider(),
        spacer,
        SimpleTooltip(
          message: 'Combine DMX or Motor cable into Sneak/Motor Multi',
          child: IconButton.outline(
              onPressed: onCombineIntoMultiButtonPressed,
              icon: const Icon(Icons.merge)),
        ),
        spacer,
        SimpleTooltip(
          message: 'Split Sneak or Motor Multi',
          child: IconButton.outline(
              onPressed: onSplitMultiButtonPressed,
              icon: const Icon(Icons.call_split)),
        ),
        spacer,
        const VerticalDivider(),
        spacer,
        CableTypeSelect(
          value: defaultPowerMultiType,
          onChanged: (value) => onDefaultPowerMultiTypeChanged(value),
          allowedTypes: const {CableType.socapex, CableType.wieland6way},
        ),
        SimpleTooltip(
            message:
                'Change Selected Power Multi cables to ${switch (defaultPowerMultiType) {
              CableType.wieland6way => 'Wieland',
              CableType.socapex => 'Socapex',
              _ => '',
            }}',
            child: IconButton.ghost(
              icon: const Icon(Icons.change_circle),
              onPressed: onChangePowerMultiTypeOfSelectedCables,
            )),
        const Spacer(),
        if (infoTrailer != null) infoTrailer!,
        SimpleTooltip(
          message: availabilityDrawOpen
              ? 'Close Availability drawer'
              : 'Open Availability drawer',
          child: IconButton.secondary(
            icon: const Icon(Icons.factory),
            onPressed: () => onShowAvailabilityDrawPressed(),
          ),
        )
      ],
    );
  }
}
