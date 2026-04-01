import 'package:flutter/material.dart';

class ArcConnector extends StatelessWidget {
  final Offset start;
  final Offset end;
  final Color color;
  final double width;
  final Radius arcRadius;
  final bool clockwise;
  final String? label;

  const ArcConnector({
    super.key,
    required this.start,
    required this.end,
    this.color = Colors.blue,
    this.width = 2.0,
    this.arcRadius = const Radius.circular(100),
    this.clockwise = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArcPainter(
        start: start,
        end: end,
        color: color,
        width: width,
        arcRadius: arcRadius,
        clockwise: clockwise,
        label: label,
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double width;
  final Radius arcRadius;
  final bool clockwise;
  final String? label;

  ArcPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.width,
    required this.arcRadius,
    required this.label,
    this.clockwise = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arcPath = Path();
    arcPath.moveTo(start.dx, start.dy);

    arcPath.arcToPoint(
      end,
      radius: arcRadius,
      clockwise: clockwise,
      largeArc: true,
    );

    canvas.drawPath(arcPath, paint);

    _drawLabel(arcPath, canvas, size);
  }

  void _drawLabel(
    Path path,
    Canvas canvas,
    Size size,
  ) {
    if (label == null) {
      return;
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final tangent = metric.getTangentForOffset(metric.length / 2);
    if (tangent == null) return;
    final summit = tangent.position;

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
    );

    final textSpan = TextSpan(text: label, style: textStyle);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: textSpan,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    // Center the text on the summit point.
    // Adjust vertically based on clockwise direction to keep it outside the arc.
    final double yOffset = clockwise ? -textPainter.height : 0;
    final textOffset = Offset(
      summit.dx - textPainter.width / 2,
      summit.dy + yOffset,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color ||
        oldDelegate.width != width ||
        oldDelegate.arcRadius != arcRadius ||
        oldDelegate.clockwise != clockwise ||
        oldDelegate.label != label;
  }
}
