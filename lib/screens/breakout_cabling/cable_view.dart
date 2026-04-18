import 'dart:math';
import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:sidekick/widgets/connector_painters.dart';

class CableView extends StatelessWidget {
  final CableViewViewModel vm;

  const CableView({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.elements.isEmpty) {
      return const SizedBox.shrink();
    }
    return InteractiveViewer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = ViewportTransformer.fromFixtures(
            fixtures: vm.elements
                .whereType<FixtureElement>()
                .map((e) => e.fixtureVm.fixture)
                .toList(),
            constraints: constraints,
          );

          return Stack(children: [
            // Edges (Cables)
            ...vm.edges.map((edge) {
              final source = edge.sourceElement;
              final destination = edge.destinationElement;
              final sourceOffset =
                  viewport.transform(source.screenX, source.screenY);
              final destinationOffset =
                  viewport.transform(destination.screenX, destination.screenY);

              return Positioned.fill(
                  child: switch (edge) {
                CableEdgeElement() => switch (edge.type) {
                    CableType.unknown => throw UnimplementedError(),
                    CableType.wieland6way => throw UnimplementedError(),
                    CableType.sneak => throw UnimplementedError(),
                    CableType.dmx => _DataCableEdge(
                        from: sourceOffset,
                        to: destinationOffset,
                        color: Colors.blue,
                        label: '${edge.length}m'),
                    CableType.hoist => throw UnimplementedError(),
                    CableType.hoistMulti => throw UnimplementedError(),
                    CableType.au10a || CableType.socapex => _PowerCableEdge(
                        from: sourceOffset,
                        to: destinationOffset,
                        label: '${edge.length}m',
                        width: switch (edge.runType) {
                          CableRunType.link => 0.75,
                          CableRunType.fixtureRun => 1,
                          CableRunType.homeRun => 2,
                        },
                        color: switch (edge.runType) {
                          CableRunType.link => Colors.red.shade800,
                          CableRunType.fixtureRun => Colors.red,
                          CableRunType.homeRun => Colors.red.shade300,
                        }),
                  }
              });
            }),

            // Nodes (Fixtures, Headers etc)
            ...vm.elements.map((node) {
              final origin = viewport.transform(node.screenX, node.screenY);
              return switch (node) {
                LocationElement() => Positioned(
                    width: 24,
                    height: 24,
                    left: origin.dx,
                    top: origin.dy,
                    child: const FractionalTranslation(
                        translation: Offset(-0.5, -0.5),
                        child: _LocationNode())),
                FixtureElement() => Positioned(
                    width: 24,
                    height: 24,
                    left: origin.dx,
                    top: origin.dy,
                    child: FractionalTranslation(
                      // Shift the node by half its own size so the coordinate is at its center.
                      translation: const Offset(-0.5, -0.5),
                      child: _FixtureNode(vm: node.fixtureVm),
                    ),
                  ),
                PowerMultiHeaderElement() => Positioned(
                    width: 16,
                    height: 16,
                    left: origin.dx,
                    top: origin.dy,
                    child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: _PowerMultiNode(vm: node.powerMultiVm)))
              };
            })
          ]);
        },
      ),
    );
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
  const _LocationNode({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      color: Colors.yellow,
    );
  }
}

class _FixtureNode extends StatelessWidget {
  final FixtureViewModel vm;
  const _FixtureNode({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          color: Theme.of(context).colorScheme.card,
          border: Border.all(
            color: Theme.of(context).colorScheme.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vm.fixture.fid.toString(),
              style: Theme.of(context).typography.mono.copyWith(fontSize: 6),
              textAlign: TextAlign.center,
              overflow: TextOverflow.clip,
            ),
            Text(
              vm.fixtureType.shortName,
              style:
                  Theme.of(context).typography.extraLight.copyWith(fontSize: 4),
              textAlign: TextAlign.center,
              overflow: TextOverflow.clip,
            )
          ],
        ));
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
          color: Colors.red,
          border: Border.all(
            color: Theme.of(context).colorScheme.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vm.name,
              style: Theme.of(context).typography.mono.copyWith(fontSize: 6),
              textAlign: TextAlign.center,
              overflow: TextOverflow.clip,
            ),
          ],
        ));
  }
}

class _PowerCableEdge extends StatelessWidget {
  final Offset from;
  final Offset to;
  final String? label;
  final double width;
  final Color color;
  const _PowerCableEdge({
    required this.from,
    required this.to,
    this.label,
    this.width = 1,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ArcConnector(
        start: from,
        end: to,
        color: color,
        width: width,
        label: label,
        arcRadius: const Radius.elliptical(20, 20));
  }
}

class _DataCableEdge extends StatelessWidget {
  final Offset from;
  final Offset to;
  final String? label;
  final Color color;
  const _DataCableEdge({
    required this.from,
    required this.to,
    this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ArcConnector(
        start: from,
        end: to,
        color: color,
        width: 2,
        label: label,
        clockwise: false,
        arcRadius: const Radius.elliptical(20, 20));
  }
}
