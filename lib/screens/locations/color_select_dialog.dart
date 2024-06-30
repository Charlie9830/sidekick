import 'package:flutter/material.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/screens/locations/color_chit.dart';

class ColorSelectDialog extends StatefulWidget {
  final Color color;

  const ColorSelectDialog({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<ColorSelectDialog> createState() => _ColorSelectDialogState();
}

class _ColorSelectDialogState extends State<ColorSelectDialog> {
  late Color _color;

  @override
  void initState() {
    _color = widget.color;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('Select Colour'),
        content: SizedBox(
          width: 464,
          height: 64,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: NamedColors.names.entries.map((entry) {
              return SelectableColorChit(
                color: entry.key,
                isSelected: _color == entry.key,
                onSelect: () => setState(() => _color = entry.key),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Apply'),
            onPressed: () => Navigator.of(context).pop(_color),
          )
        ]);
  }
}
