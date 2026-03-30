import 'dart:math';
import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/screens/breakout_cabling/build_cabling_graph.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:sidekick/widgets/arc_painter.dart';

class CableView extends StatelessWidget {
  final Map<String, FixtureViewModel> fixtureVms;

  const CableView({super.key, required this.fixtureVms});

  @override
  Widget build(BuildContext context) {
    if (fixtureVms.isEmpty) {
      return const SizedBox.shrink();
    }

    final powerVerticies = _getPowerVerticies();
    final dataVerticies = _getDataVerticies();

    final mergedVerticies = fixtureVms.keys.map((fixtureId) {
      final powerVertex = powerVerticies[fixtureId];
      final dataVertex = dataVerticies[fixtureId];

      return _ConcreteVertex.merge(powerVertex, dataVertex);
    });

    return InteractiveViewer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = ViewportTransformer.fromFixtures(
            fixtures: mergedVerticies.map((v) => v.local.fixture).toList(),
            constraints: constraints,
          );

          return Stack(
            children: mergedVerticies
                .map((vertex) {
                  final origin = viewport.transform(
                      vertex.local.fixture.x, vertex.local.fixture.y);

                  return [
                    if (vertex.edges.isNotEmpty)
                      ...vertex.edges.map((edge) {
                        return Positioned.fill(
                            child: switch (edge.edge.cableType) {
                          CableType.au10a => _PowerCableEdge(
                              from: origin,
                              to: viewport.transform(
                                  edge.to.fixture.x, edge.to.fixture.y),
                              label:
                                  '${(edge.edge.cableLength * 0.001).floor()}m'),
                          CableType.dmx => _DataCableEdge(
                              from: origin,
                              to: viewport.transform(
                                  edge.to.fixture.x, edge.to.fixture.y),
                              label:
                                  '${(edge.edge.cableLength * 0.001).floor()}m'),
                          _ => Text('Woops'),
                        });
                      }),
                    Positioned(
                      width: 96,
                      height: 64,
                      left: origin.dx,
                      top: origin.dy,
                      child: FractionalTranslation(
                        // Shift the node by half its own size so the coordinate is at its center.
                        translation: const Offset(-0.5, -0.5),
                        child: _FixtureNode(
                            vm: fixtureVms[vertex.local.fixture.uid]!),
                      ),
                    ),
                  ];
                })
                .flattened
                .toList(),
          );
        },
      ),
    );
  }

  Map<String, _ConcreteVertex> _getPowerVerticies() {
    final powerGraph = buildPowerCableGraph(
        fixtures: fixtureVms.values
            .map((i) => i.fixture)
            .sorted((a, b) => a.sequence - b.sequence));

    return Map<String, _ConcreteVertex>.fromEntries(
        powerGraph.data.entries.map((entry) {
      final current = entry.key;
      final edgeEntries = entry.value.entries;

      return MapEntry(
          current.fixture.uid,
          _ConcreteVertex(
              local: current,
              edges: edgeEntries
                  .map(((edgeEntry) => _ConcreteEdge(
                      edge: edgeEntry.value, from: current, to: edgeEntry.key)))
                  .toList()));
    }));
  }

  Map<String, _ConcreteVertex> _getDataVerticies() {
    final dataGraph = buildDataCableGraph(
        fixtures: fixtureVms.values
            .map((i) => i.fixture)
            .sorted((a, b) => a.sequence - b.sequence));

    return Map<String, _ConcreteVertex>.fromEntries(
        dataGraph.data.entries.map((entry) {
      final current = entry.key;
      final edgeEntries = entry.value.entries;

      return MapEntry(
          current.fixture.uid,
          _ConcreteVertex(
              local: current,
              edges: edgeEntries
                  .map(((edgeEntry) => _ConcreteEdge(
                      edge: edgeEntry.value, from: current, to: edgeEntry.key)))
                  .toList()));
    }));
  }
}

class _ConcreteVertex {
  final FixtureVertex local;
  final List<_ConcreteEdge> edges;

  _ConcreteVertex({
    required this.local,
    required this.edges,
  });

  factory _ConcreteVertex.merge(_ConcreteVertex? a, _ConcreteVertex? b) {
    if (a != null) {
      return _ConcreteVertex(local: a.local, edges: [
        ...a.edges,
        if (b != null) ...b.edges,
      ]);
    }

    if (b != null) {
      return _ConcreteVertex(
          local: b.local, edges: [if (a != null) ...a.edges, ...b.edges]);
    }

    throw 'Invalid Concrete Vertex merger';
  }
}

class _ConcreteEdge {
  final EdgeData edge;
  final FixtureVertex from;
  final FixtureVertex to;

  _ConcreteEdge({
    required this.edge,
    required this.from,
    required this.to,
  });
}

/// Helper class to handle the translation of physical fixture coordinates (MM)
/// into logical screen coordinates (Pixels).
class ViewportTransformer {
  final double scale;
  final double offsetX;
  final double offsetY;
  final double minX;
  final double minY;

  ViewportTransformer._({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.minX,
    required this.minY,
  });

  factory ViewportTransformer.fromFixtures({
    required List<FixtureModel> fixtures,
    required BoxConstraints constraints,
    double padding = 40.0,
  }) {
    double minX = fixtures.map((f) => f.x).minOrNull ?? 0;
    double maxX = fixtures.map((f) => f.x).maxOrNull ?? 0;
    double minY = fixtures.map((f) => f.y).minOrNull ?? 0;
    double maxY = fixtures.map((f) => f.y).maxOrNull ?? 0;

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
      offsetX: offsetX,
      offsetY: offsetY,
      minX: minX,
      minY: minY,
    );
  }

  Offset transform(double x, double y) {
    return Offset(
      (x - minX) * scale + offsetX,
      (y - minY) * scale + offsetY,
    );
  }
}

class _FixtureNode extends StatelessWidget {
  final FixtureViewModel vm;
  const _FixtureNode({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(6),
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
            Text(vm.fixture.fid.toString(),
                style:
                    Theme.of(context).typography.mono.copyWith(fontSize: 14)),
            Text(
              vm.fixtureType.shortName,
              style: Theme.of(context)
                  .typography
                  .extraLight
                  .copyWith(fontSize: 12),
              overflow: TextOverflow.clip,
            )
          ],
        ));
  }
}

class _PowerCableEdge extends StatelessWidget {
  final Offset from;
  final Offset to;
  final String? label;
  const _PowerCableEdge(
      {super.key, required this.from, required this.to, this.label});

  @override
  Widget build(BuildContext context) {
    return ArcConnector(
        start: from,
        end: to,
        color: Colors.red,
        width: 2,
        label: label,
        arcRadius: const Radius.elliptical(20, 20));
  }
}

class _DataCableEdge extends StatelessWidget {
  final Offset from;
  final Offset to;
  final String? label;
  const _DataCableEdge(
      {super.key, required this.from, required this.to, this.label});

  @override
  Widget build(BuildContext context) {
    return ArcConnector(
        start: from,
        end: to,
        color: Colors.blue,
        width: 2,
        label: label,
        clockwise: false,
        arcRadius: const Radius.elliptical(20, 20));
  }
}
