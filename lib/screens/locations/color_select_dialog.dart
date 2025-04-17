import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/named_color_model.dart';
import 'package:sidekick/screens/locations/color_chit.dart';

class ColorSelectDialog extends StatefulWidget {
  final LabelColorModel color;

  const ColorSelectDialog({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<ColorSelectDialog> createState() => _ColorSelectDialogState();
}

class _ColorSelectDialogState extends State<ColorSelectDialog> {
  late LabelColorModel _color;
  late final ScrollController _scrollController;

  @override
  void initState() {
    _color = widget.color.copyWith();

    _scrollController = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            const Expanded(child: Text('Select Colour')),
            IconButton(
                onPressed: () => setState(() {
                      _color = _color.copyWith(
                          colors: _color.colors.toList()..removeLast());
                    }),
                icon: const Icon(Icons.remove_circle)),
            IconButton(
                onPressed: () => setState(
                      () {
                        _color = _color.copyWith(
                          colors: _color.colors.toList()..add(NamedColors.none),
                        );

                        _scrollController.animateTo(1000,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut);
                      },
                    ),
                icon: const Icon(Icons.add_circle)),
          ],
        ),
        content: SizedBox(
            width: 564,
            height: 200,
            child: Column(
              children: [
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    children: _color.colors.mapIndexed((index, namedColor) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _SelectableColorRow(
                            value: namedColor,
                            number: index + 1,
                            onChanged: (newValue) => setState(() {
                                  final newList = _color.colors.toList();
                                  newList[index] = newValue;

                                  _color = _color.copyWith(
                                    colors: newList,
                                  );
                                })),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
              ],
            )),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _SelectableColorRow extends StatelessWidget {
  final NamedColorModel value;
  final int number;
  final void Function(NamedColorModel value) onChanged;

  const _SelectableColorRow({
    required this.value,
    required this.number,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Colour $number', style: Theme.of(context).textTheme.labelSmall),
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: NamedColors.names.entries.map((entry) {
            return SelectableColorChit(
              value: entry.key,
              isSelected: value.name == entry.key.name,
              onSelect: () => onChanged(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}
