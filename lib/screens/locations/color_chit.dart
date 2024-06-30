import 'package:flutter/material.dart';

class ColorChit extends StatelessWidget {
  final Color color;

  const ColorChit({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (color.alpha == 0) {
      return const Icon(Icons.palette, size: 16, color: Colors.grey);
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class SelectableColorChit extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final void Function() onSelect;

  const SelectableColorChit({
    Key? key,
    required this.color,
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
              child: ColorChit(color: color),
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
