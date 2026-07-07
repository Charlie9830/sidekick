import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

class HybridTag extends StatelessWidget {
  final List<String> otherLocationNames;
  const HybridTag({
    super.key,
    required this.otherLocationNames,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleTooltip(
      message: _resolveOtherLocationsText(otherLocationNames),
      child: Container(
        decoration: BoxDecoration(
            color: SidekickColors.neutralFlag,
            borderRadius: BorderRadius.circular(4.0)),
        padding: const EdgeInsets.all(4.0),
        child: Text('Hybrid', style: Theme.of(context).typography.small),
      ),
    );
  }

  String _resolveOtherLocationsText(List<String> otherLocationNames) {
    return otherLocationNames.join(', ');
  }
}
