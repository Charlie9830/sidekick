import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/utils/electrical_equations.dart';

class BalanceGauge extends StatelessWidget {
  final double phaseALoad;
  final double phaseBLoad;
  final double phaseCLoad;

  const BalanceGauge(
      {Key? key,
      required this.phaseALoad,
      required this.phaseBLoad,
      required this.phaseCLoad})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (phaseALoad == 0 && phaseBLoad == 0 && phaseCLoad == 0) {
      return const SizedBox();
    }

    return Row(
      children: [
        Text(
            '${calculateNeutralCurrent(phaseALoad, phaseBLoad, phaseCLoad).floor()}A'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              value: calculateBalanceRatio(phaseALoad, phaseBLoad, phaseCLoad),
              strokeWidth: 5,
              backgroundColor: Colors.blue,
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  double _selectGreatestDeviation(double a, double b, double c) {
    if (a < b && a < c) {
      return a;
    }

    if (b < a && b < c) {
      return b;
    }

    return c;
  }
}
