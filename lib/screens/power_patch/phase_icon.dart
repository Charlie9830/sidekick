import 'package:flutter/material.dart';

const double _kSize = 16;

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
        width: _kSize,
        height: _kSize,
        margin: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          shape: BoxShape.circle,
        ),
      );
    }

    if (phaseNumber == 2) {
      return Container(
        width: _kSize,
        height: _kSize,
        margin: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white60,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      width: _kSize,
      height: _kSize,
      margin: const EdgeInsets.all(12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        shape: BoxShape.circle,
      ),
    );
  }
}
