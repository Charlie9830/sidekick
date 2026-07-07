import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/view_projection.dart';
import 'package:sidekick/cable_graph/viewport_transformer.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

const ViewProjection _kProjection = PlanProjection();
const double _kNodeSize = 30;

/// Inset kept clear around the plot so edge nodes aren't clipped. Much smaller
/// than the cable view's default — this pane is only a few hundred pixels wide,
/// and the default 240px would zero out the fit scale and stack every node.
const double _kPlanPadding = 48;

/// A top-down plot of the selected fixtures used to assign sequence numbers by
/// clicking fixtures in physical order.
///
/// Tapping an unassigned fixture calls [onAssign]; tapping an assigned one calls
/// [onUnassign]. A polyline connects assigned fixtures in sequence order so the
/// operator can see the path they are drawing.
class SequencerPlanView extends StatelessWidget {
  final List<FixtureModel> fixtures;
  final Map<String, FixtureTypeModel> fixtureTypes;

  /// Sequence number → fixture, as currently assigned in the dialog.
  final Map<int, FixtureModel> mapping;

  final void Function(FixtureModel fixture) onAssign;
  final void Function(FixtureModel fixture) onUnassign;

  const SequencerPlanView({
    super.key,
    required this.fixtures,
    required this.fixtureTypes,
    required this.mapping,
    required this.onAssign,
    required this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    if (fixtures.isEmpty) {
      return const SizedBox.shrink();
    }

    final sequenceByUid = <String, int>{
      for (final entry in mapping.entries) entry.value.uid: entry.key,
    };

    final positions = <String, Offset>{
      for (final fixture in fixtures)
        fixture.uid: _kProjection.project(fixture.x, fixture.y, fixture.z),
    };

    return InteractiveViewer(
      maxScale: 50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = ViewportTransformer.fit(
            points: positions.values,
            constraints: constraints,
            padding: _kPlanPadding,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SequencePathPainter(
                    mapping: mapping,
                    positions: positions,
                    viewport: viewport,
                    color: SidekickColors.selectionAccent,
                  ),
                ),
              ),
              ...fixtures.map((fixture) {
                final origin = viewport.transform(
                  positions[fixture.uid]!.dx,
                  positions[fixture.uid]!.dy,
                );
                final sequence = sequenceByUid[fixture.uid];
                return Positioned(
                  width: _kNodeSize,
                  height: _kNodeSize,
                  left: origin.dx,
                  top: origin.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: _FixtureNode(
                      fixture: fixture,
                      typeName: fixtureTypes[fixture.typeId]?.name ?? '',
                      sequence: sequence,
                      onTap: () => sequence == null
                          ? onAssign(fixture)
                          : onUnassign(fixture),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _FixtureNode extends StatelessWidget {
  final FixtureModel fixture;
  final String typeName;
  final int? sequence;
  final VoidCallback onTap;

  const _FixtureNode({
    required this.fixture,
    required this.typeName,
    required this.sequence,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAssigned = sequence != null;
    final label = isAssigned ? sequence.toString() : fixture.fid.toString();

    return SimpleTooltip(
      message:
          '#${fixture.fid}'
          '${typeName.isEmpty ? '' : ' · $typeName'}'
          '${isAssigned ? ' · Seq $sequence' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            color: isAssigned
                ? SidekickColors.selectionAccent
                : theme.colorScheme.card,
            border: Border.all(
              color: isAssigned
                  ? SidekickColors.selectionAccent
                  : theme.colorScheme.border,
            ),
          ),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Text(
                label,
                style: theme.typography.mono.copyWith(
                  fontSize: 10,
                  color: isAssigned
                      ? Colors.white
                      : theme.colorScheme.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
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
