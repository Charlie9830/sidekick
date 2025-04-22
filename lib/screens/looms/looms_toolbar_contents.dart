import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/cable_model.dart';

class LoomsToolbarContents extends StatelessWidget {
  final void Function() onCombineIntoSneakPressed;
  final void Function() onSplitSneakIntoDmxPressed;
  final void Function()? onDeleteSelectedCables;
  final void Function(CableType type) onDefaultPowerMultiTypeChanged;
  final void Function()? onChangePowerMultiTypeOfSelectedCables;
  final CableType defaultPowerMultiType;
  final Widget? infoTrailer;

  const LoomsToolbarContents({
    super.key,
    required this.onCombineIntoSneakPressed,
    required this.onSplitSneakIntoDmxPressed,
    required this.onDeleteSelectedCables,
    required this.defaultPowerMultiType,
    required this.onDefaultPowerMultiTypeChanged,
    required this.onChangePowerMultiTypeOfSelectedCables,
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
          message: 'Combine DMX into Sneak',
          child: IconButton.filled(
              onPressed: onCombineIntoSneakPressed,
              icon: const Icon(Icons.merge)),
        ),
        spacer,
        Tooltip(
          message: 'Split Sneak into DMX',
          child: IconButton.filled(
              onPressed: onSplitSneakIntoDmxPressed,
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
      ],
    );
  }
}
