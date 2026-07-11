import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/viewport_transformer.dart';

/// Paints truss footprints beneath the rig's nodes and cables.
///
/// Each hull is an ordered outline already projected into diagram space (mm);
/// only the viewport fit remains, so a truss lands in the same frame as its
/// fixtures and cables.
class TrussPainter extends CustomPainter {
  final List<List<Offset>> hulls;
  final ViewportTransformer viewport;
  final Color color;

  TrussPainter({
    required this.hulls,
    required this.viewport,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final hull in hulls) {
      if (hull.length < 2) continue;

      final path = Path();
      final start = viewport.transform(hull.first.dx, hull.first.dy);
      path.moveTo(start.dx, start.dy);
      for (final point in hull.skip(1)) {
        final p = viewport.transform(point.dx, point.dy);
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TrussPainter oldDelegate) {
    return oldDelegate.hulls != hulls ||
        oldDelegate.viewport != viewport ||
        oldDelegate.color != color;
  }
}
