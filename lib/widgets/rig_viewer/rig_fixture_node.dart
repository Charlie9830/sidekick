import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/view_projection.dart';
import 'package:sidekick/cable_graph/viewport_transformer.dart';
import 'package:sidekick/redux/models/fixture_geometry_model.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/widgets/rig_viewer/fixture_geometry_painter.dart';

/// A fixture marker inside a [RigViewer].
///
/// When the fixture type has imported GDTF geometry the node paints its real
/// footprint (each part's projected outline at physical scale); otherwise it
/// falls back to the rounded placeholder card. Construct it through
/// [RigFixtureNode.positioned], which sizes and places the node over the
/// fixture's projected footprint inside the viewer's Stack.
class RigFixtureNode extends StatelessWidget {
  /// Projected part outlines and their bounds (diagram mm, fixture-relative),
  /// from [projectedPartHulls] / [projectedHullBounds]. Null bounds paints the
  /// placeholder card instead.
  final List<List<Offset>> hulls;
  final Rect? bounds;

  final String label;
  final String? subLabel;

  /// Highlights the node (e.g. a fixture with an assigned sequence number).
  final bool selected;

  /// Opacity of the labels, driven by the viewer's zoom level so text only
  /// appears once it is large enough to read.
  final double labelOpacity;

  final String? tooltip;
  final VoidCallback? onTap;

  const RigFixtureNode({
    super.key,
    this.hulls = const [],
    this.bounds,
    required this.label,
    this.subLabel,
    this.selected = false,
    this.labelOpacity = 1,
    this.tooltip,
    this.onTap,
  });

  /// Builds a [RigFixtureNode] positioned over the fixture's projected
  /// footprint.
  ///
  /// [diagramPosition] is the fixture's projected origin (diagram mm). With
  /// [geometry], the node covers the geometry's exact projected bounds — which
  /// need not be centred on the origin — scaled to physical size by
  /// [viewport]. Without geometry (or when its footprint is degenerate) the
  /// node is a [fallbackSize] square centred on the fixture.
  static Positioned positioned({
    Key? key,
    required Offset diagramPosition,
    required ViewportTransformer viewport,
    required double fallbackSize,
    FixtureGeometryModel? geometry,
    double rotationZ = 0,
    ViewProjection projection = const PlanProjection(),
    required String label,
    String? subLabel,
    bool selected = false,
    double labelOpacity = 1,
    String? tooltip,
    VoidCallback? onTap,
  }) {
    final origin = viewport.transform(diagramPosition.dx, diagramPosition.dy);

    final hulls = geometry == null
        ? const <List<Offset>>[]
        : projectedPartHulls(geometry, rotationZ, projection);
    final bounds = projectedHullBounds(hulls);

    final node = RigFixtureNode(
      key: key,
      hulls: hulls,
      bounds: bounds,
      label: label,
      subLabel: subLabel,
      selected: selected,
      labelOpacity: labelOpacity,
      tooltip: tooltip,
      onTap: onTap,
    );

    if (bounds == null) {
      return Positioned(
        width: fallbackSize,
        height: fallbackSize,
        left: origin.dx,
        top: origin.dy,
        child: FractionalTranslation(
          // Shift the node by half its own size so the coordinate is at its
          // center.
          translation: const Offset(-0.5, -0.5),
          child: node,
        ),
      );
    }

    return Positioned(
      left: origin.dx + bounds.left * viewport.scale,
      top: origin.dy + bounds.top * viewport.scale,
      width: bounds.width * viewport.scale,
      height: bounds.height * viewport.scale,
      child: node,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bounds = this.bounds;

    final Widget node = bounds == null
        ? Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              color: selected
                  ? SidekickColors.selectionAccent
                  : theme.colorScheme.card,
              border: Border.all(
                color: selected
                    ? SidekickColors.selectionAccent
                    : theme.colorScheme.border,
              ),
            ),
            child: _buildLabels(theme),
          )
        : CustomPaint(
            painter: FixtureGeometryPainter(
              hulls: hulls,
              bounds: bounds,
              fillColor: selected
                  ? SidekickColors.selectionAccent.withValues(alpha: 0.75)
                  : theme.colorScheme.card.withValues(alpha: 0.85),
              strokeColor: selected
                  ? SidekickColors.selectionAccent
                  : theme.colorScheme.border,
            ),
            child: Center(child: _buildLabels(theme)),
          );

    // Opaque so taps land anywhere in the node's box — a background
    // CustomPaint is not itself hit-testable.
    final interactive = onTap == null
        ? node
        : GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: node,
          );

    return tooltip == null
        ? interactive
        : SimpleTooltip(message: tooltip, child: interactive);
  }

  Widget? _buildLabels(ThemeData theme) {
    if (labelOpacity <= 0) {
      return null;
    }

    final labelColor = selected ? Colors.white : theme.colorScheme.foreground;

    return Opacity(
      opacity: labelOpacity,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: theme.typography.mono.copyWith(
                  fontSize: 10,
                  color: labelColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: theme.typography.light.copyWith(
                    fontSize: 7,
                    color: labelColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.clip,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
