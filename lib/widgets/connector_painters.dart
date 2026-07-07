import 'dart:math';
import 'package:flutter/material.dart';

/// Draws a cable as an orthogonal "channel": it leaves [start] perpendicular to
/// the truss (vertically), runs parallel to the truss at a plateau, then
/// descends into [end]. The corners are rounded by [cornerRadius].
///
/// [riser] is the perpendicular distance the plateau sits from the outermost
/// endpoint. [directionUp] routes the plateau above the truss (`true`, used for
/// home runs) or below it (`false`, used for links and fixture runs).
class ChannelConnector extends StatelessWidget {
  final Offset start;
  final Offset end;
  final Color color;
  final double width;
  final double riser;
  final double cornerRadius;
  final bool directionUp;
  final String? label;

  const ChannelConnector({
    super.key,
    required this.start,
    required this.end,
    this.color = Colors.blue,
    this.width = 2.0,
    this.riser = 40,
    this.cornerRadius = 8,
    this.directionUp = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChannelConnectorPainter(
        start: start,
        end: end,
        color: color,
        width: width,
        riser: riser,
        cornerRadius: cornerRadius,
        directionUp: directionUp,
        label: label,
      ),
    );
  }
}

class ChannelConnectorPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double width;
  final double riser;
  final double cornerRadius;
  final bool directionUp;
  final String? label;

  ChannelConnectorPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.width,
    required this.riser,
    required this.cornerRadius,
    required this.directionUp,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _buildPath();
    canvas.drawPath(path, paint);
    _drawLabel(path, canvas, size);
  }

  /// Builds the channel path. In screen space Y grows downward, so an upward
  /// riser subtracts from Y. The plateau is measured from the outermost
  /// endpoint so it always clears both, even when the endpoints sit at
  /// different heights (e.g. a home-run header lifted off the truss line).
  Path _buildPath() {
    final path = Path()..moveTo(start.dx, start.dy);

    // Outward direction and plateau level.
    final plateauY = directionUp
        ? min(start.dy, end.dy) - riser
        : max(start.dy, end.dy) + riser;

    final dx = end.dx - start.dx;

    // Degenerate: no horizontal travel — a channel collapses to a straight
    // line, so just connect the points directly.
    if (dx.abs() < 1) {
      path.lineTo(end.dx, end.dy);
      return path;
    }

    final hx = dx.sign; // horizontal run direction (+1 right, -1 left)
    final startVy = (plateauY - start.dy).sign; // start leg direction
    final endVy = (end.dy - plateauY).sign; // end leg direction

    // Clamp the radius so it never exceeds any adjacent segment.
    final r = [
      cornerRadius,
      (plateauY - start.dy).abs(),
      (plateauY - end.dy).abs(),
      dx.abs() / 2,
    ].reduce(min);

    // Start leg up to the first corner.
    path.lineTo(start.dx, plateauY - startVy * r);
    // Rounded corner into the horizontal run.
    path.quadraticBezierTo(
      start.dx,
      plateauY,
      start.dx + hx * r,
      plateauY,
    );
    // Horizontal run along the plateau.
    path.lineTo(end.dx - hx * r, plateauY);
    // Rounded corner into the descending leg.
    path.quadraticBezierTo(
      end.dx,
      plateauY,
      end.dx,
      plateauY + endVy * r,
    );
    // Descend into the end point.
    path.lineTo(end.dx, end.dy);

    return path;
  }

  void _drawLabel(Path path, Canvas canvas, Size size) {
    if (label == null) return;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final tangent = metric.getTangentForOffset(metric.length / 2);
    if (tangent == null) return;
    final summit = tangent.position;

    const textStyle = TextStyle(color: Colors.white, fontSize: 6);
    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: textSpan,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);

    // Keep the label on the outward side of the plateau.
    final double yOffset = directionUp ? -textPainter.height : 0;
    final textOffset = Offset(
      summit.dx - textPainter.width / 2,
      summit.dy + yOffset,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant ChannelConnectorPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color ||
        oldDelegate.width != width ||
        oldDelegate.riser != riser ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.directionUp != directionUp ||
        oldDelegate.label != label;
  }
}
