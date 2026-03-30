import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:graphview/GraphView.dart';

class CableGraphGraphView extends StatefulWidget {
  final BreakoutCablingViewModel vm;
  const CableGraphGraphView({
    super.key,
    required this.vm,
  });

  @override
  State<CableGraphGraphView> createState() => _CableGraphGraphViewState();
}

class _CableGraphGraphViewState extends State<CableGraphGraphView> {
  final Graph _graph = Graph();
  late final GraphViewController _controller;
  late final BuchheimWalkerConfiguration _config;

  @override
  void initState() {
    _controller = GraphViewController();
    _config = BuchheimWalkerConfiguration(
      levelSeparation: 200,
      orientation: BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM,
      siblingSeparation: 100,
      subtreeSeparation: 100,
    );

    final fixtures =
        widget.vm.fixtureMap.values.sorted((a, b) => a.sequence - b.sequence);
    final fixturePatchChains =
        fixtures.groupListsBy((fixture) => fixture.powerPatch);

    final nodeCache = <String, Node>{};
    Node getNode(String id) => nodeCache.putIfAbsent(id, () => Node.Id(id));

    for (final entry in fixturePatchChains.entries) {
      final fixtures = entry.value;

      if (fixtures.length == 1) {
        _graph.addNode(getNode(fixtures.first.uid));
        continue;
      }

      for (int i = 0; i < fixtures.length; i++) {
        final currentFixture = fixtures[i];
        final nextFixture = fixtures.elementAtOrNull(i + 1);

        if (nextFixture != null) {
          _graph.addEdge(getNode(currentFixture.uid), getNode(nextFixture.uid),
              paint: Paint()
                ..color = Colors.blue
                ..strokeWidth = 2);
        }
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: GraphView.builder(
          animated: false,
          controller: _controller,
          graph: _graph,
          algorithm:
              TidierTreeLayoutAlgorithm(_config, TreeEdgeRenderer(_config)),
          builder: (node) => Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.gray,
                ),
                alignment: Alignment.center,
                child: Text(widget.vm.fixtureMap[node.key?.value as String]?.fid
                        .toString() ??
                    '-'),
              )),
    );
  }
}
