import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/utils/electrical_equations.dart';

enum Variance {
  normal,
  small,
}

class BalanceGauge extends StatelessWidget {
  final double phaseALoad;
  final double phaseBLoad;
  final double phaseCLoad;
  final Variance variance;

  const BalanceGauge({
    Key? key,
    required this.phaseALoad,
    required this.phaseBLoad,
    required this.phaseCLoad,
    this.variance = Variance.normal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (phaseALoad == 0 && phaseBLoad == 0 && phaseCLoad == 0) {
      return const SizedBox();
    }

    const divider = VerticalDivider(endIndent: 4, indent: 4, width: 16);
    final imbalanceRatio =
        calculateImbalanceRatio(phaseALoad, phaseBLoad, phaseCLoad);
    final imbalancePercent = (imbalanceRatio * 100).round();

    return Row(
      children: [
        Text('${phaseALoad.round().toString()}A',
            style: Theme.of(context).typography.large.copyWith(
                  fontSize: variance == Variance.small ? 14 : null,
                  color: Colors.red,
                )),
        divider,
        Text('${phaseBLoad.round().toString()}A',
            style: Theme.of(context).typography.large.copyWith(
                  fontSize: variance == Variance.small ? 14 : null,
                  color: Colors.white,
                )),
        divider,
        Text('${phaseCLoad.round().toString()}A',
            style: Theme.of(context).typography.large.copyWith(
                  fontSize: variance == Variance.small ? 14 : null,
                  color: Colors.blue,
                )),
        SizedBox(width: variance == Variance.small ? 16 : 24),
        FocusCard(
          '${calculateNeutralCurrent(phaseALoad, phaseBLoad, phaseCLoad).floor()}A',
          variance: variance,
        ),
        const SizedBox(width: 8),
        FocusCard(
          '${imbalancePercent.toString()}%',
          variance: variance,
        ),
      ],
    );
  }
}

class FocusCard extends StatelessWidget {
  final String text;
  final Variance variance;

  const FocusCard(
    this.text, {
    this.variance = Variance.normal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: variance == Variance.small ? 32 : 48,
      height: variance == Variance.small ? 24 : 32,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: Theme.of(context).colorScheme.border,
      ),
      child: Text(
        text,
        style: variance == Variance.small
            ? Theme.of(context).typography.small
            : Theme.of(context).typography.normal,
        textAlign: TextAlign.center,
      ),
    );
  }
}
