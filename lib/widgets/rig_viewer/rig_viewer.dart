import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/cable_graph/view_projection.dart';
import 'package:sidekick/cable_graph/viewport_transformer.dart';
import 'package:sidekick/widgets/hover_region.dart';
import 'package:sidekick/widgets/rig_viewer/truss_painter.dart';

/// Below [_kLabelFadeStart] node labels are hidden; above [_kLabelFadeEnd]
/// they are fully opaque. Between the two they fade in — semantic zoom that
/// keeps the rig uncluttered when zoomed out and legible when zoomed in,
/// instead of rendering sub-pixel text.
const double _kLabelFadeStart = 1.6;
const double _kLabelFadeEnd = 3.2;

/// Builds the widgets of one rig layer, given the fitted viewport, the
/// projection of the currently selected orthogonal view, and the zoom-driven
/// label opacity. Content must project its own world coordinates through
/// [projection] so every layer re-orients together when the view changes.
/// Returned widgets sit directly in the viewer's Stack, so they must be
/// [Positioned] (or otherwise Stack-legal).
typedef RigViewerLayerBuilder =
    List<Widget> Function(
      BuildContext context,
      ViewportTransformer viewport,
      ViewProjection projection,
      double labelOpacity,
    );

/// A pannable, zoomable, 2D view of the rig, shared by the cable view and the
/// sequencer plan view.
///
/// The viewer owns the chrome both views used to duplicate: the
/// [InteractiveViewer], the [ViewportTransformer] fit over [fitPoints], the
/// truss footprint underlay, the zoom-driven label fade, and the orthogonal
/// view selector (Top / Bottom / Front / Back / Left / Right). The selected
/// view's projection is handed to the layer builders, so all inputs are
/// world-space (mm, Z-up). Content stays with the caller — [underlayBuilder]
/// draws beneath the nodes (cables, sequence paths) and [nodesBuilder] places
/// the nodes themselves, both receiving the fitted viewport and projection so
/// everything shares one world-to-screen mapping. [overlays] are screen-fixed
/// chrome (legends, controls) outside the pan/zoom surface.
class RigViewer extends StatefulWidget {
  /// World-space points (mm) the viewport must fit around, in addition to the
  /// corners of [trussCorners]. An empty list collapses the viewer to nothing.
  final List<Vector3> fitPoints;

  /// Inset kept clear around the plot so edge nodes aren't clipped.
  final double fitPadding;

  final double maxScale;

  /// World-space corner sets, one per truss, whose projected outlines are
  /// painted beneath everything else.
  final List<List<Vector3>> trussCorners;

  final RigViewerLayerBuilder? underlayBuilder;
  final RigViewerLayerBuilder nodesBuilder;

  /// Screen-fixed widgets stacked over the viewer (legends, control panels).
  final List<Widget> overlays;

  /// The orthogonal view shown until the user selects another.
  final OrthogonalView initialView;

  const RigViewer({
    super.key,
    required this.fitPoints,
    required this.nodesBuilder,
    this.underlayBuilder,
    this.fitPadding = 240,
    this.maxScale = 50,
    this.trussCorners = const [],
    this.overlays = const [],
    this.initialView = OrthogonalView.top,
  });

  @override
  State<RigViewer> createState() => _RigViewerState();
}

class _RigViewerState extends State<RigViewer> {
  final TransformationController _controller = TransformationController();
  double _labelOpacity = 0;
  late OrthogonalView _view = widget.initialView;

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

  void _handleViewChanged(OrthogonalView view) {
    if (view == _view) return;
    setState(() {
      _view = view;
      // A new view has new bounds; reset pan/zoom so the fit is visible.
      _controller.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fitPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final hulls = [
      for (final corners in widget.trussCorners)
        convexHull([for (final corner in corners) _view.projectVector(corner)]),
    ];

    final fitPoints = [
      for (final point in widget.fitPoints) _view.projectVector(point),
      for (final hull in hulls) ...hull,
    ];

    return Stack(
      children: [
        InteractiveViewer(
          maxScale: widget.maxScale,
          transformationController: _controller,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport = ViewportTransformer.fit(
                points: fitPoints,
                constraints: constraints,
                padding: widget.fitPadding,
              );

              return Stack(
                children: [
                  if (hulls.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TrussPainter(
                          hulls: hulls,
                          viewport: viewport,
                          color: Theme.of(context).colorScheme.mutedForeground,
                        ),
                      ),
                    ),
                  ...?widget.underlayBuilder?.call(
                    context,
                    viewport,
                    _view,
                    _labelOpacity,
                  ),
                  ...widget.nodesBuilder(
                    context,
                    viewport,
                    _view,
                    _labelOpacity,
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
            child: _ViewSelector(
              selected: _view,
              onChanged: _handleViewChanged,
            ),
          ),
        ),
        ...widget.overlays,
      ],
    );
  }
}

/// Segmented control switching the viewer between the six orthogonal views.
class _ViewSelector extends StatelessWidget {
  final OrthogonalView selected;
  final ValueChanged<OrthogonalView> onChanged;

  const _ViewSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return HoverRegionBuilder(
      builder: (context, isHovering) {
        return Opacity(
          opacity: isHovering ? 1 : 0.25,
          child: Card(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                for (final view in OrthogonalView.values)
                  _ViewSegment(
                    view: view,
                    selected: view == selected,
                    onPressed: () => onChanged(view),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ViewSegment extends StatelessWidget {
  final OrthogonalView view;
  final bool selected;
  final VoidCallback onPressed;

  const _ViewSegment({
    required this.view,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(view.label);
    return selected
        ? PrimaryButton(
            size: ButtonSize.small,
            onPressed: onPressed,
            child: label,
          )
        : GhostButton(
            size: ButtonSize.small,
            onPressed: onPressed,
            child: label,
          );
  }
}
