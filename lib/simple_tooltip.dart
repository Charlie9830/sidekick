import 'package:shadcn_flutter/shadcn_flutter.dart';

class SimpleTooltip extends StatelessWidget {
  final Widget child;
  final String? message;
  final Duration waitDuration;
  final Duration showDuration;
  final Duration minDuration;
  const SimpleTooltip({
    super.key,
    required this.child,
    required this.message,
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(milliseconds: 200),
    this.minDuration = const Duration(milliseconds: 0),
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return child;
    }

    return Tooltip(
      tooltip: (context) => SurfaceCard(child: Text(message!)),
      waitDuration: waitDuration,
      showDuration: showDuration,
      minDuration: minDuration,
      child: child,
    );
  }
}
