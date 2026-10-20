import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/fixture_geometry_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/widgets/rig_viewer/camera/rig_camera_state.dart';
import 'package:sidekick/widgets/rig_viewer/chrome/tool_bar.dart';
import 'package:sidekick/widgets/rig_viewer/rig_viewer.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_fixture_builder.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_scene_model.dart';

/// Width (mm) of the line drawn through assigned fixtures in sequence order.
const double _kSequencePathWidthMm = 25;

/// A 3D view of the selected fixtures used to assign sequence numbers by
/// clicking fixtures in physical order.
///
/// Clicking an unassigned fixture calls [onAssign]; clicking an assigned one
/// calls [onUnassign]. Assigned fixtures are tinted and joined by a line in
/// sequence order so the operator can see the path they are drawing. The
/// viewer's Rotate Selection / Fit Selected work on the assigned fixtures.
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
      scene: RigSceneModel(
        fixtures: [
          for (final fixture in fixtures)
            _buildFixture(fixture, sequence: sequenceByUid[fixture.uid]),
        ],
        lines: [?_sequencePath()],
      ),
      focusIds: sequenceByUid.keys.toSet(),
      initialPreset: RigViewPreset.top,
      initialMode: RigToolMode.select,
      initialShowConnectors: false,
      onFixtureTap: (id) => _handleFixtureTap(id, sequenceByUid),
    );
  }

  RigFixture _buildFixture(FixtureModel fixture, {required int? sequence}) {
    final typeName = fixtureTypes[fixture.typeId]?.name ?? '';
    final isAssigned = sequence != null;

    return buildRigFixture(
      fixture: fixture,
      geometry: fixtureGeometries[fixture.typeId],
      fixtureType: fixtureTypes[fixture.typeId],
      color: isAssigned ? SidekickColors.rigAssigned : SidekickColors.rigMesh,
      label: isAssigned ? sequence.toString() : fixture.fid.toString(),
      tooltip:
          '#${fixture.fid}'
          '${typeName.isEmpty ? '' : ' · $typeName'}'
          '${isAssigned ? ' · Seq $sequence' : ''}',
    );
  }

  /// The assignment order as a line through the assigned fixtures, or null
  /// until two fixtures are assigned.
  RigLine? _sequencePath() {
    final points = [
      for (final sequence in mapping.keys.toList()..sort())
        if (mapping[sequence] case final fixture?)
          Vector3(fixture.x, fixture.y, fixture.z),
    ];
    if (points.length < 2) return null;

    return RigLine(
      points: points,
      color: SidekickColors.rigAssigned,
      width: _kSequencePathWidthMm,
    );
  }

  void _handleFixtureTap(String id, Map<String, int> sequenceByUid) {
    final fixture = fixtures.firstWhereOrNull((f) => f.uid == id);
    if (fixture == null) return;

    sequenceByUid.containsKey(id) ? onUnassign(fixture) : onAssign(fixture);
  }
}
