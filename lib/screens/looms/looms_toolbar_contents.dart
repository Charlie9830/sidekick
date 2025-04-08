import 'package:flutter/material.dart';

class LoomsToolbarContents extends StatelessWidget {
  final void Function() onCombineIntoSneakPressed;
  const LoomsToolbarContents({
    super.key,
    required this.onCombineIntoSneakPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          
            onPressed: onCombineIntoSneakPressed, icon: const Icon(Icons.merge))
      ],
    );
  }
}
