import 'package:shadcn_flutter/shadcn_flutter.dart';

class ShadListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool enabled;
  final bool selected;

  const ShadListItem({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.enabled = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: subtitle == null ? 36 : 56,
      child: AbsorbPointer(
        absorbing: !enabled,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            color: selected
                ? Theme.of(context).colorScheme.border
                : Colors.transparent,
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12.0)],
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                        style: Theme.of(context).typography.small.copyWith(
                            color: enabled
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .mutedForeground),
                        child: title),
                    if (subtitle != null)
                      DefaultTextStyle(
                          style: Theme.of(context).typography.textMuted,
                          child: subtitle!),
                  ],
                )),
                if (trailing != null)
                  DefaultTextStyle(
                      style: Theme.of(context).typography.small.copyWith(
                          color: enabled
                              ? null
                              : Theme.of(context).colorScheme.mutedForeground),
                      child: trailing!),
              ],
            )),
      ),
    );
  }
}
