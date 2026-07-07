import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

const double _kSize = 16;

class PhaseIcon extends StatelessWidget {
  final int phaseNumber;
  const PhaseIcon({
    Key? key,
    this.phaseNumber = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = switch (phaseNumber) {
      1 => SidekickColors.phase1,
      2 => SidekickColors.phase2,
      _ => SidekickColors.phase3,
    };

    return Container(
      width: _kSize,
      height: _kSize,
      margin: const EdgeInsets.all(12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
