import 'dart:math';
import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/screens/breakout_cabling/visibility_control.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:sidekick/widgets/connector_painters.dart';

/// Below [_kLabelFadeStart] the fixture labels are hidden; above
/// [_kLabelFadeEnd] they are fully opaque. Between the two they fade in —
/// semantic zoom that keeps the graph uncluttered when zoomed out and
/// legible when zoomed in, instead of rendering sub-pixel text.
const double _kLabelFadeStart = 1.6;
const double _kLabelFadeEnd = 3.2;

class CableView extends StatefulWidget {
  final CableViewViewModel vm;

  const CableView({super.key, required this.vm});

  @override
  State<CableView> createState() => _CableViewState();
}

class _CableViewState extends State<CableView> {
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
    if (widget.vm.elements.isEmpty) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        InteractiveViewer(
          maxScale: 50,
          transformationController: _controller,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport = ViewportTransformer.fromFixtures(
                fixtures: widget.vm.elements
                    .whereType<FixtureElement>()
                    .map((e) => e.fixtureVm.fixture)
                    .toList(),
                constraints: constraints,
              );

              return Stack(
                children: [
                  // Truss geometry (drawn beneath the cabling).
                  if (widget.vm.trusses.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TrussPainter(
                          trusses: widget.vm.trusses,
                          viewport: viewport,
                          color: Theme.of(context).colorScheme.mutedForeground,
                        ),
                      ),
                    ),

                  // Edges (Cables)
                  ...widget.vm.edges.map((edge) {
                    final fromElement = edge.fromElement;
                    final toElement = edge.toElement;
                    final fromOffset = viewport.transform(
                      fromElement.screenX,
                      fromElement.screenY,
                    );
                    final toOffset = viewport.transform(
                      toElement.screenX,
                      toElement.screenY,
                    );

                    return Positioned.fill(
                      child: switch (edge) {
                        PsuedoEdgeElement() => const SizedBox(),
                        CableEdgeElement() => switch (edge.type) {
                          CableType.unknown => throw UnimplementedError(),
                          CableType.wieland6way => throw UnimplementedError(),
                          CableType.sneak => throw UnimplementedError(),
                          CableType.hoist => throw UnimplementedError(),
                          CableType.hoistMulti => throw UnimplementedError(),
                          CableType.true1 => throw UnimplementedError(),
                          CableType.dmx => _buildDataCableEdge(
                            edge: edge,
                            fromOffset: fromOffset,
                            toOffset: toOffset,
                          ),
                          CableType.au10a ||
                          CableType.socapex => _buildPowerCableEdge(
                            edge: edge,
                            fromOffset: fromOffset,
                            toOffset: toOffset,
                          ),
                          CableType.socapexToAu10ALampHeader =>
                            throw UnimplementedError(),
                          CableType.socapexToTrue1LampHeader =>
                            throw UnimplementedError(),
                          CableType.wieland6WayLampHeader =>
                            throw UnimplementedError(),
                          CableType.sneakLampHeader =>
                            throw UnimplementedError(),
                          CableType.hoistMultiLampHeader =>
                            throw UnimplementedError(),
                          CableType.hoistMultiRackHeader =>
                            throw UnimplementedError(),
                        },
                      },
                    );
                  }),

                  // Nodes (Fixtures, Headers etc)
                  ...widget.vm.elements.map((node) {
                    final origin = viewport.transform(
                      node.screenX,
                      node.screenY,
                    );
                    return switch (node) {
                      LocationElement() => Positioned(
                        width: 10,
                        height: 10,
                        left: origin.dx,
                        top: origin.dy,
                        child: const FractionalTranslation(
                          translation: Offset(-0.5, -0.5),
                          child: _LocationNode(),
                        ),
                      ),
                      FixtureElement() => Positioned(
                        width: 16,
                        height: 16,
                        left: origin.dx,
                        top: origin.dy,
                        child: FractionalTranslation(
                          // Shift the node by half its own size so the coordinate is at its center.
                          translation: const Offset(-0.5, -0.5),
                          child: _FixtureNode(
                            vm: node.fixtureVm,
                            labelOpacity: _labelOpacity,
                          ),
                        ),
                      ),
                      PowerMultiHeaderElement() => Positioned(
                        width: 16,
                        height: 16,
                        left: origin.dx,
                        top: origin.dy,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, -0.5),
                          child: _PowerMultiNode(vm: node.powerMultiVm),
                        ),
                      ),
                      DataMultiHeaderElement() => Positioned(
                        width: 16,
                        height: 16,
                        left: origin.dx,
                        top: origin.dy,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, -0.5),
                          child: _DataMultiNode(outletName: node.outletName),
                        ),
                      ),
                      DataPatchHeaderElement() => Positioned(
                        width: 16,
                        height: 16,
                        left: origin.dx,
                        top: origin.dy,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, -0.5),
                          child: _DataPatchNode(
                            outletName: node.outletName,
                            universe: node.universe,
                          ),
                        ),
                      ),
                      TrussBreakElement() => Positioned(
                        width: 6,
                        height: 6,
                        left: origin.dx,
                        top: origin.dy,
                        child: const FractionalTranslation(
                          translation: Offset(-0.5, -0.5),
                          child: _TrussBreakNode(),
                        ),
                      ),
                    };
                  }),
                ],
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          width: 164,
          child: VisibilityControl(
            state: widget.vm.cableVisibility,
            onVisibilityChanged: widget.vm.onVisibilityChanged,
          ),
        ),
        const Positioned(
          bottom: 8,
          left: 8,
          child: _Legend(),
        ),
      ],
    );
  }

  Widget _buildDataCableEdge({
    required CableEdgeElement edge,
    required Offset fromOffset,
    required Offset toOffset,
  }) {
    if (widget.vm.cableVisibility.dataState.contains(edge.runType) == false) {
      return const SizedBox();
    }

    return _DataCableEdge(
      from: fromOffset,
      to: toOffset,
      runType: edge.runType,
      label: _formatLength(edge.length),
    );
  }

  Widget _buildPowerCableEdge({
    required CableEdgeElement edge,
    required Offset fromOffset,
    required Offset toOffset,
  }) {
    if (widget.vm.cableVisibility.powerState.contains(edge.runType) == false) {
      return const SizedBox();
    }

    return _PowerCableEdge(
      from: fromOffset,
      to: toOffset,
      label: _formatLength(edge.length),
      runType: edge.runType,
    );
  }

  String _formatLength(double length) {
    return length.remainder(1) == 0
        ? '${length.toStringAsFixed(0)}m'
        : '${length.toStringAsFixed(1)}m';
  }
}

/// Helper class to handle the translation of physical fixture coordinates (MM)
/// into logical screen coordinates (Pixels).
class ViewportTransformer {
  final double scale;
  final double centeringOffsetX;
  final double centeringOffsetY;
  final double minX;
  final double minY;

  ViewportTransformer._({
    required this.scale,
    required this.centeringOffsetX,
    required this.centeringOffsetY,
    required this.minX,
    required this.minY,
  });

  factory ViewportTransformer.fromFixtures({
    required List<FixtureModel> fixtures,
    required BoxConstraints constraints,
    double padding = 240.0,
  }) {
    double minX = fixtures.map((f) => f.screenX).minOrNull ?? 0;
    double maxX = fixtures.map((f) => f.screenX).maxOrNull ?? 0;
    double minY = fixtures.map((f) => f.screenY).minOrNull ?? 0;
    double maxY = fixtures.map((f) => f.screenY).maxOrNull ?? 0;

    final mmWidth = maxX - minX;
    final mmHeight = maxY - minY;

    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final drawWidth = max(0.0, screenWidth - (padding * 2));
    final drawHeight = max(0.0, screenHeight - (padding * 2));

    double scale = 1.0;
    if (mmWidth > 0 || mmHeight > 0) {
      final scaleX = mmWidth > 0 ? drawWidth / mmWidth : double.infinity;
      final scaleY = mmHeight > 0 ? drawHeight / mmHeight : double.infinity;
      scale = min(scaleX, scaleY);
      if (scale == double.infinity) scale = 1.0;
    }

    final offsetX = (screenWidth - (mmWidth * scale)) / 2;
    final offsetY = (screenHeight - (mmHeight * scale)) / 2;

    return ViewportTransformer._(
      scale: scale,
      centeringOffsetX: offsetX,
      centeringOffsetY: offsetY,
      minX: minX,
      minY: minY,
    );
  }

  Offset transform(double x, double y) {
    return Offset(
      (x - minX) * scale + centeringOffsetX,
      (y - minY) * scale + centeringOffsetY,
    );
  }
}

class _LocationNode extends StatelessWidget {
  const _LocationNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: SidekickColors.locationMarker,
      ),
    );
  }
}

class _TrussBreakNode extends StatelessWidget {
  const _TrussBreakNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.background,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
    );
  }
}

class _FixtureNode extends StatelessWidget {
  final FixtureViewModel vm;

  /// Opacity of the fid/type labels, driven by the viewer's zoom level so the
  /// text only appears once it is large enough to read.
  final double labelOpacity;

  const _FixtureNode({required this.vm, this.labelOpacity = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: Theme.of(context).colorScheme.card,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: labelOpacity <= 0
          ? null
          : Opacity(
              opacity: labelOpacity,
              child: FittedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vm.fixture.fid.toString(),
                      style: Theme.of(context)
                          .typography
                          .mono
                          .copyWith(fontSize: 6),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.clip,
                    ),
                    Text(
                      vm.fixtureType.shortName,
                      style: Theme.of(context)
                          .typography
                          .light
                          .copyWith(fontSize: 4),
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

/// A compact key explaining the graph's colour (cable type) and line-weight
/// (run type) encodings.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.typography.xSmall
        .copyWith(color: theme.colorScheme.mutedForeground);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Legend', style: theme.typography.xSmall.copyWith(
              color: theme.colorScheme.foreground,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _LegendSwatch(
              color: SidekickColors.powerRun, label: 'Power', style: labelStyle),
          _LegendSwatch(
              color: SidekickColors.dataRun, label: 'Data', style: labelStyle),
          _LegendSwatch(
              color: SidekickColors.dataMultiNode,
              label: 'Data multi',
              style: labelStyle),
          _LegendSwatch(
              color: SidekickColors.locationMarker,
              label: 'Location',
              style: labelStyle),
          const SizedBox(height: 8),
          _LegendLine(weight: 1, label: 'Link', style: labelStyle),
          _LegendLine(weight: 2, label: 'Fixture run', style: labelStyle),
          _LegendLine(weight: 3, label: 'Home run', style: labelStyle),
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final TextStyle style;

  const _LegendSwatch({
    required this.color,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: style),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final double weight;
  final String label;
  final TextStyle style;

  const _LegendLine({
    required this.weight,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            child: Divider(
              thickness: weight,
              color: Theme.of(context).colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: style),
        ],
      ),
    );
  }
}

class _PowerMultiNode extends StatelessWidget {
  final PowerMultiHeaderViewModel vm;
  const _PowerMultiNode({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SidekickColors.powerMultiNode,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Text(
        vm.name,
        style: Theme.of(context).typography.mono.copyWith(fontSize: 6),
        textAlign: TextAlign.center,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class _DataMultiNode extends StatelessWidget {
  final String outletName;

  const _DataMultiNode({required this.outletName});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: SidekickColors.dataMultiNode,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Text(
        outletName,
        style: Theme.of(context).typography.mono.copyWith(fontSize: 6),
        textAlign: TextAlign.center,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class _DataPatchNode extends StatelessWidget {
  final String outletName;
  final int universe;

  const _DataPatchNode({required this.outletName, required this.universe});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SidekickColors.dataMultiNode,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Text(
        'U$universe',
        style: Theme.of(context).typography.mono.copyWith(fontSize: 6),
        textAlign: TextAlign.center,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

/// Paints each truss stick as an oriented rectangle in the same viewport space
/// as the fixtures and cables, giving a physical footprint for the rig.
class _TrussPainter extends CustomPainter {
  final List<TrussViewModel> trusses;
  final ViewportTransformer viewport;
  final Color color;

  _TrussPainter({
    required this.trusses,
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

    for (final truss in trusses) {
      final radians = truss.rotationZ * pi / 180.0;
      final axisX = cos(radians);
      final axisY = sin(radians);
      final perpX = -sin(radians);
      final perpY = cos(radians);
      final halfLength = truss.length / 2;
      final halfWidth = truss.width / 2;

      Offset corner(double along, double across) {
        final worldX = truss.x + axisX * along + perpX * across;
        final worldY = truss.y + axisY * along + perpY * across;
        // Fixtures negate Y to move from world to screen space; match that here.
        return viewport.transform(worldX, -worldY);
      }

      final c1 = corner(halfLength, halfWidth);
      final c2 = corner(halfLength, -halfWidth);
      final c3 = corner(-halfLength, -halfWidth);
      final c4 = corner(-halfLength, halfWidth);

      final path = Path()
        ..moveTo(c1.dx, c1.dy)
        ..lineTo(c2.dx, c2.dy)
        ..lineTo(c3.dx, c3.dy)
        ..lineTo(c4.dx, c4.dy)
        ..close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrussPainter oldDelegate) {
    return oldDelegate.trusses != trusses ||
        oldDelegate.viewport != viewport ||
        oldDelegate.color != color;
  }
}

class _PowerCableEdge extends StatelessWidget {
  final Offset from;
  final Offset to;
  final String? label;
  final CableRunType runType;

  const _PowerCableEdge({
    required this.from,
    required this.to,
    required this.runType,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ArcConnector(
      start: from,
      end: to,
      color: switch (runType) {
        CableRunType.link => SidekickColors.powerLink,
        CableRunType.fixtureRun => SidekickColors.powerRun,
        CableRunType.homeRun => SidekickColors.powerHome,
      },
      width: switch (runType) {
        CableRunType.link => 1,
        CableRunType.fixtureRun => 1,
        CableRunType.homeRun => 2,
      },
      label: label,
      arcRadius: const Radius.elliptical(20, 20),
    );
  }
}

class _DataCableEdge extends StatelessWidget {
  final Offset from;
  final Offset to;
  final String? label;
  final CableRunType runType;

  const _DataCableEdge({
    required this.from,
    required this.to,
    required this.runType,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ArcConnector(
      start: from,
      end: to,
      color: switch (runType) {
        CableRunType.link => SidekickColors.dataLink,
        CableRunType.fixtureRun => SidekickColors.dataRun,
        CableRunType.homeRun => SidekickColors.dataHome,
      },
      width: switch (runType) {
        CableRunType.link => 1,
        CableRunType.fixtureRun => 1,
        CableRunType.homeRun => 2,
      },
      label: label,
      clockwise: false,
      arcRadius: const Radius.elliptical(20, 20),
    );
  }
}
