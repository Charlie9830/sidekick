import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/cable_model.dart';

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
        Tooltip(
            message: 'Delete selected Cables',
            child: IconButton.outlined(
                onPressed: onDeleteSelectedCables,
                icon: const Icon(Icons.delete))),
        spacer,
        const VerticalDivider(),
        spacer,
        Tooltip(
          message: 'Combine DMX or Motor cable into Sneak/Motor Multi',
          child: IconButton.filled(
              onPressed: onCombineIntoMultiButtonPressed,
              icon: const Icon(Icons.merge)),
        ),
        spacer,
        Tooltip(
          message: 'Split Sneak or Motor Multi',
          child: IconButton.filled(
              onPressed: onSplitMultiButtonPressed,
              icon: const Icon(Icons.call_split)),
        ),
        spacer,
        const VerticalDivider(),
        spacer,
        DropdownMenu<CableType>(
          initialSelection: defaultPowerMultiType,
          onSelected: (value) => onDefaultPowerMultiTypeChanged(value!),
          enableFilter: false,
          enableSearch: false,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: CableType.socapex, label: 'Socapex'),
            DropdownMenuEntry(value: CableType.wieland6way, label: '6way'),
          ],
        ),
        Tooltip(
            message:
                'Change Selected Power Multi cables to ${switch (defaultPowerMultiType) {
              CableType.wieland6way => 'Wieland',
              CableType.socapex => 'Socapex',
              _ => '',
            }}',
            child: IconButton(
              icon: const Icon(Icons.change_circle),
              onPressed: onChangePowerMultiTypeOfSelectedCables,
            )),
        const Spacer(),
        if (infoTrailer != null) infoTrailer!,
        Tooltip(
          message: availabilityDrawOpen
              ? 'Close Availability drawer'
              : 'Open Availability drawer',
          child: IconButton.filledTonal(
            isSelected: availabilityDrawOpen,
            icon: const Icon(Icons.factory),
            onPressed: () => onShowAvailabilityDrawPressed(),
          ),
        )
      ],
    );
  }
}
