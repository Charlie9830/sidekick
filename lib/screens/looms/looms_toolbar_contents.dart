import 'package:flutter/material.dart';

class LoomsToolbarContents extends StatelessWidget {
  final void Function() onCombineIntoSneakPressed;
  final void Function() onSplitSneakIntoDmxPressed;

  const LoomsToolbarContents({
    super.key,
    required this.onCombineIntoSneakPressed,
    required this.onSplitSneakIntoDmxPressed,
  });

  @override
  Widget build(BuildContext context) {
    const Widget spacer = SizedBox(width: 8);
    return Row(
      
      children: [
        Tooltip(
          message: 'Combine DMX into Sneak',
          child: IconButton.filled(
              onPressed: onCombineIntoSneakPressed, icon: const Icon(Icons.merge)),
        ),

        spacer,

         Tooltip(
          message: 'Split Sneak into DMX',
          child: IconButton.filled(
              onPressed: onSplitSneakIntoDmxPressed, icon: const Icon(Icons.call_split)),
        )
      ],
    );
  }
}
