import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

/// A small filled status chip used to annotate cables and looms.
///
/// Prefer passing a semantic token from [SidekickColors] (e.g.
/// `SidekickColors.warning`, `SidekickColors.motor`) as [color] so the flag
/// vocabulary stays consistent across screens. Defaults to a neutral steel
/// chip when no colour is given.
class CableFlag extends StatelessWidget {
  final Color? color;
  final String text;

  const CableFlag({
    super.key,
    this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 36),
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color ?? SidekickColors.neutralFlag,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context)
            .typography
            .xSmall
            .copyWith(fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }
}
