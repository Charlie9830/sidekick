import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/cable_model.dart';

class PowerMultiSelector extends StatelessWidget {
  final void Function(CableType value) onChanged;
  final void Function() onChangedExistingPressed;
  final CableType value;

  const PowerMultiSelector({
    super.key,
    required this.onChanged,
    required this.onChangedExistingPressed,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownMenu<CableType>(
          enableFilter: false,
          enableSearch: false,
          initialSelection: CableType.socapex,
          onSelected: (newValue) => onChanged(newValue ?? value),
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: CableType.socapex, label: 'Socapex'),
            DropdownMenuEntry(
                value: CableType.wieland6way, label: 'Wieland 6way')
          ],
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Change existing cables',
          child: IconButton(
              onPressed: onChangedExistingPressed,
              icon: const Icon(Icons.change_circle)),
        )
      ],
    );
  }
}
