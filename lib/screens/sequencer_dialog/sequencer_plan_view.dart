import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/cable_graph/view_projection.dart';
import 'package:sidekick/cable_graph/viewport_transformer.dart';
import 'package:sidekick/redux/models/fixture_geometry_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/widgets/rig_viewer/rig_fixture_node.dart';
import 'package:sidekick/widgets/rig_viewer/rig_viewer.dart';

/// Fallback node size (px) for fixture types without imported geometry.
const double _kNodeSize = 30;

/// Inset kept clear around the plot so edge nodes aren't clipped. Much smaller
/// than the cable view's default — this pane is only a few hundred pixels wide,
/// and the default 240px would zero out the fit scale and stack every node.
const double _kPlanPadding = 48;

/// A plot of the selected fixtures (top-down by default, switchable to any
/// orthogonal view) used to assign sequence numbers by clicking fixtures in
/// physical order.
///
/// Tapping an unassigned fixture calls [onAssign]; tapping an assigned one calls
/// [onUnassign]. A polyline connects assigned fixtures in sequence order so the
/// operator can see the path they are drawing. Fixture types with imported
/// GDTF geometry are drawn at their physical footprint.
class SequencerPlanView extends StatelessWidget {
  final List<FixtureModel> fixtures;
  final Map<String, FixtureTypeModel> fixtureTypes;

  /// Imported GDTF geometry keyed by fixture type uid.
  final Map<String, FixtureGeometryModel> fixtureGeometries;

  /// Sequence number → fixture, as currently assigned in the dialog.
  final Map<int, FixtureModel> mapping;

  final void Function(FixtureModel fixture) onAssign;
  final void Function(FixtureModel fixture) onUnassign;

  const SequencerPlanView({
    super.key,
    required this.fixtures,
    required this.fixtureTypes,
    required this.fixtureGeometries,
    required this.mapping,
    required this.onAssign,
    required this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    final sequenceByUid = <String, int>{
      for (final entry in mapping.entries) entry.value.uid: entry.key,
    };

    return RigViewer(
      fitPoints: [
        for (final fixture in fixtures)
          Vector3(fixture.x, fixture.y, fixture.z),
      ],
      fitPadding: _kPlanPadding,
      underlayBuilder: (context, viewport, projection, labelOpacity) => [
        Positioned.fill(
          child: CustomPaint(
            painter: _SequencePathPainter(
              mapping: mapping,
              positions: _projectPositions(projection),
              viewport: viewport,
              color: SidekickColors.selectionAccent,
            ),
          ),
        ),
      ],
      nodesBuilder: (context, viewport, projection, labelOpacity) {
        final positions = _projectPositions(projection);
        return [
          for (final fixture in fixtures)
            _buildFixtureNode(
              fixture: fixture,
              viewport: viewport,
              projection: projection,
              sequence: sequenceByUid[fixture.uid],
              diagramPosition: positions[fixture.uid]!,
            ),
        ];
      },
    );
  }

  /// Each fixture's diagram-space position under [projection], keyed by uid.
  Map<String, Offset> _projectPositions(ViewProjection projection) => {
    for (final fixture in fixtures)
      fixture.uid: projection.project(fixture.x, fixture.y, fixture.z),
  };

  Positioned _buildFixtureNode({
    required FixtureModel fixture,
    required ViewportTransformer viewport,
    required ViewProjection projection,
    required int? sequence,
    required Offset diagramPosition,
  }) {
    final typeName = fixtureTypes[fixture.typeId]?.name ?? '';
    final isAssigned = sequence != null;

    return RigFixtureNode.positioned(
      key: Key(fixture.uid),
      diagramPosition: diagramPosition,
      viewport: viewport,
      fallbackSize: _kNodeSize,
      geometry: fixtureGeometries[fixture.typeId],
      rotationZ: fixture.rotationZ,
      projection: projection,
      label: isAssigned ? sequence.toString() : fixture.fid.toString(),
      selected: isAssigned,
      tooltip:
          '#${fixture.fid}'
          '${typeName.isEmpty ? '' : ' · $typeName'}'
          '${isAssigned ? ' · Seq $sequence' : ''}',
      onTap: () => isAssigned ? onUnassign(fixture) : onAssign(fixture),
    );
  }
}

/// Draws the assignment order as a polyline through the assigned fixtures.
class _SequencePathPainter extends CustomPainter {
  final Map<int, FixtureModel> mapping;
  final Map<String, Offset> positions;
  final ViewportTransformer viewport;
  final Color color;

  _SequencePathPainter({
    required this.mapping,
    required this.positions,
    required this.viewport,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final orderedSeq = mapping.keys.toList()..sort();
    if (orderedSeq.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    var started = false;
    for (final seq in orderedSeq) {
      final diagram = positions[mapping[seq]!.uid];
      if (diagram == null) continue;
      final p = viewport.transform(diagram.dx, diagram.dy);
      if (!started) {
        path.moveTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SequencePathPainter oldDelegate) {
    return oldDelegate.mapping != mapping ||
        oldDelegate.positions != positions ||
        oldDelegate.viewport != viewport ||
        oldDelegate.color != color;
  }
}
