import 'package:sidekick/cable_graph/graph/edges.dart';
import 'package:sidekick/cable_graph/graph/nodes.dart';

/// An immutable graph of breakout cabling, assembled once from its nodes.
///
/// Edges are owned by the node they leave, so the graph's edge set is the
/// union of every node's edges.
class CableGraph {
  final Map<String, Node> _nodes;
  final List<Edge> _edges;

  CableGraph(Iterable<Node> nodes)
    : _nodes = {for (final node in nodes) node.id: node},
      _edges = [for (final node in nodes) ...node.edges];

  Iterable<Node> get nodes => _nodes.values;
  Iterable<Edge> get edges => _edges;

  Node? getNode(String id) => _nodes[id];

  /// Depth-first traversal of every node reachable from [root].
  Iterable<Node> walk(Node root) sync* {
    final visited = <String>{};
    final stack = <Node>[root];

    while (stack.isNotEmpty) {
      final node = stack.removeLast();

      if (visited.add(node.id)) {
        yield node;
        stack.addAll(node.edges.map((edge) => _nodes[edge.to]).nonNulls);
      }
    }
  }
}
