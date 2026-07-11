import 'package:shadcn_flutter/shadcn_flutter.dart';

/// A divider with a directional arrow at its midpoint indicating the flow of
/// assignment between panes.
///
/// A [Axis.vertical] divider points right (fixtures flow to the assigned
/// list); a [Axis.horizontal] divider points down (the rig view feeds the
/// panes below it).
class ArrowedDivider extends StatelessWidget {
  final Axis axis;

  const ArrowedDivider({super.key, this.axis = Axis.vertical});

  @override
  Widget build(BuildContext context) {
    return switch (axis) {
      Axis.vertical => const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: VerticalDivider()),
          Icon(Icons.arrow_right, size: 72, color: Colors.gray),
          Expanded(child: VerticalDivider()),
        ],
      ),
      Axis.horizontal => const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Divider()),
          Icon(Icons.arrow_drop_down, size: 72, color: Colors.gray),
          Expanded(child: Divider()),
        ],
      ),
    };
  }
}
