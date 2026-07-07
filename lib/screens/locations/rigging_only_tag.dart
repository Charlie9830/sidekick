import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

class RiggingOnlyTag extends StatelessWidget {
  const RiggingOnlyTag({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleTooltip(
      message:
          'Location intended to represent "Rigging Only" locations without any Fixtures, EG: Cable Bridge, Mothergrid',
      child: Container(
        decoration: BoxDecoration(
            color: SidekickColors.neutralFlag,
            borderRadius: BorderRadius.circular(4.0)),
        padding: const EdgeInsets.all(4.0),
        child: Text('Rigging', style: Theme.of(context).typography.small),
      ),
    );
  }
}
