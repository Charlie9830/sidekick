import 'package:flutter/material.dart';

class PhaseIcon extends StatelessWidget {
  final int phaseNumber;
  const PhaseIcon({
    Key? key,
    this.phaseNumber = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (phaseNumber == 1) {
      return Container(
          margin: const EdgeInsets.all(12),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Text('1'));
    }

    if (phaseNumber == 2) {
      return Container(
          margin: const EdgeInsets.all(12),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Text('2',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.black)));
    }

    return Container(
        margin: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: const Text('3'));
  }
}
