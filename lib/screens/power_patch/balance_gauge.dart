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

    const divider = VerticalDivider(endIndent: 4, indent: 4);
    final imbalanceRatio =
        calculateImbalanceRatio(phaseALoad, phaseBLoad, phaseCLoad);
    final imbalancePercent = (imbalanceRatio * 100).round();

    return Row(
      children: [
        Text('${phaseALoad.round().toString()}A',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.red,
                )),
        divider,
        Text('${phaseBLoad.round().toString()}A',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.white,
                )),
        divider,
        Text('${phaseCLoad.round().toString()}A',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.blueAccent,
                )),
        const SizedBox(width: 24),
        FocusCard(
          '${calculateNeutralCurrent(phaseALoad, phaseBLoad, phaseCLoad).floor()}A',
        ),
        const SizedBox(width: 8),
        FocusCard('${imbalancePercent.toString()}%'),
      ],
    );
  }
}

class FocusCard extends StatelessWidget {
  final String text;

  const FocusCard(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 60,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: Theme.of(context).highlightColor,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
