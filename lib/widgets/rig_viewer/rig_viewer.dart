import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/viewport_transformer.dart';
import 'package:sidekick/widgets/rig_viewer/truss_painter.dart';

/// Below [_kLabelFadeStart] node labels are hidden; above [_kLabelFadeEnd]
/// they are fully opaque. Between the two they fade in — semantic zoom that
/// keeps the rig uncluttered when zoomed out and legible when zoomed in,
/// instead of rendering sub-pixel text.
const double _kLabelFadeStart = 1.6;
const double _kLabelFadeEnd = 3.2;

/// Builds the widgets of one rig layer, given the fitted viewport and the
/// zoom-driven label opacity. Returned widgets sit directly in the viewer's
/// Stack, so they must be [Positioned] (or otherwise Stack-legal).
typedef RigViewerLayerBuilder =
    List<Widget> Function(
      BuildContext context,
      ViewportTransformer viewport,
      double labelOpacity,
    );

/// A pannable, zoomable, 2D view of the rig, shared by the cable view and the
/// sequencer plan view.
///
/// The viewer owns the chrome both views used to duplicate: the
/// [InteractiveViewer], the [ViewportTransformer] fit over [fitPoints], the
/// truss footprint underlay and the zoom-driven label fade. Content stays with
/// the caller — [underlayBuilder] draws beneath the nodes (cables, sequence
/// paths) and [nodesBuilder] places the nodes themselves, both receiving the
/// fitted viewport so everything shares one diagram-to-screen mapping.
/// [overlays] are screen-fixed chrome (legends, controls) outside the
/// pan/zoom surface.
class RigViewer extends StatefulWidget {
  /// Diagram-space points (mm) the viewport must fit around. An empty list
  /// collapses the viewer to nothing.
  final List<Offset> fitPoints;

  /// Inset kept clear around the plot so edge nodes aren't clipped.
  final double fitPadding;

  final double maxScale;

  /// Truss footprints (diagram mm) painted beneath everything else.
  final List<List<Offset>> trussHulls;

  final RigViewerLayerBuilder? underlayBuilder;
  final RigViewerLayerBuilder nodesBuilder;

  /// Screen-fixed widgets stacked over the viewer (legends, control panels).
  final List<Widget> overlays;

  const RigViewer({
    super.key,
    required this.fitPoints,
    required this.nodesBuilder,
    this.underlayBuilder,
    this.fitPadding = 240,
    this.maxScale = 50,
    this.trussHulls = const [],
    this.overlays = const [],
  });

  @override
  State<RigViewer> createState() => _RigViewerState();
}

class _RigViewerState extends State<RigViewer> {
  final TransformationController _controller = TransformationController();
  double _labelOpacity = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final opacity =
        ((scale - _kLabelFadeStart) / (_kLabelFadeEnd - _kLabelFadeStart))
            .clamp(0.0, 1.0);
    if ((opacity - _labelOpacity).abs() > 0.02) {
      setState(() => _labelOpacity = opacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fitPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        InteractiveViewer(
          maxScale: widget.maxScale,
          transformationController: _controller,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport = ViewportTransformer.fit(
                points: widget.fitPoints,
                constraints: constraints,
                padding: widget.fitPadding,
              );

              return Stack(
                children: [
                  if (widget.trussHulls.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TrussPainter(
                          hulls: widget.trussHulls,
                          viewport: viewport,
                          color: Theme.of(context).colorScheme.mutedForeground,
                        ),
                      ),
                    ),
                  ...?widget.underlayBuilder?.call(
                    context,
                    viewport,
                    _labelOpacity,
                  ),
                  ...widget.nodesBuilder(context, viewport, _labelOpacity),
                ],
              );
            },
          ),
        ),
        ...widget.overlays,
      ],
    );
  }
}
