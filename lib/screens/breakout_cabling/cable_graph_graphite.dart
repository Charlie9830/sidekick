import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:graphite/graphite.dart';

import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

class CableGraphGraphite extends StatefulWidget {
  final BreakoutCablingViewModel vm;
  const CableGraphGraphite({
    super.key,
    required this.vm,
  });

  @override
  State<CableGraphGraphite> createState() => _CableGraphGraphiteState();
}

class _CableGraphGraphiteState extends State<CableGraphGraphite> {
  List<NodeInput> _buildNodes() {
    final fixtures = widget.vm.locationFixtureVms.values
        .map((vm) => vm.fixture)
        .sorted((a, b) => a.sequence - b.sequence);
    final fixturePatchChains =
        fixtures.groupListsBy((fixture) => fixture.powerPatch);
    final nodes = <NodeInput>[];

    for (final entry in fixturePatchChains.entries) {
      final fixtures = entry.value;
      if (fixtures.length == 1) {
        nodes.add(NodeInput(id: fixtures.first.uid, next: []));
        continue;
      }
      for (int i = 0; i < fixtures.length; i++) {
        final currentFixture = fixtures[i];
        final nextFixture = fixtures.elementAtOrNull(i + 1);
        nodes.add(NodeInput(id: currentFixture.uid, next: [
          if (nextFixture != null) EdgeInput(outcome: nextFixture.uid)
        ]));
      }
    }
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _buildNodes();
    if (nodes.isEmpty) return const SizedBox.shrink();

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3,
      constrained: false,
      child: DirectGraph(
        centered: true,
        styleBuilder: (edge) => EdgeStyle(
            linePaint: Paint()
              ..color = Colors.blue
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2),
        defaultCellSize: const Size(24, 24),
        cellPadding: const EdgeInsets.all(32),
        list: nodes,
        nodeBuilder: (context, node) {
          final fixture = widget.vm.fixtureMap[node.id];

          if (fixture == null) {
            return const Text('Null');
          }

          return Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.gray,
            ),
            child: Text(fixture.fid.toString()),
          );
        },
      ),
    );
  }
}
