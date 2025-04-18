import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/named_color_model.dart';

class ColorChit extends StatelessWidget {
  final Color color;
  final Brightness brightness;
  final double size;

  const ColorChit({
    Key? key,
    required this.color,
    this.size = 16,
    this.brightness = Brightness.light,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (color.a == 0) {
      return const Icon(Icons.palette, size: 16, color: Colors.grey);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: brightness == Brightness.dark
            ? color.withValues(alpha: 0.8)
            : color,
      ),
    );
  }
}

class SelectableColorChit extends StatelessWidget {
  final NamedColorModel value;
  final bool isSelected;
  final void Function() onSelect;

  const SelectableColorChit({
    Key? key,
    required this.value,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: InkWell(
        onTap: onSelect,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ColorChit(color: value.color),
            ),
            if (isSelected == true)
              Container(
                height: 4,
                foregroundDecoration: BoxDecoration(
                  color: Theme.of(context).highlightColor,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
