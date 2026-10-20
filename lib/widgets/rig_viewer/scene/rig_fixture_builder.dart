import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/cabling/fixture_ports.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/fixture_geometry_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/widgets/rig_viewer/scene/oriented_box.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_scene_model.dart';

/// Edge length (mm) of the stand-in cube drawn for fixture types without
/// imported GDTF geometry.
const double kPlaceholderFixtureSizeMm = 300;

/// GDTF primitive types that read better as cylinders than boxes.
const Set<String> _cylindricalPrimitives = {
  'Cylinder',
  'Conventional',
  'Conventional1_1',
  'Pigtail',
};

/// Builds the 3D viewer's description of [fixture].
///
/// With [geometry], each GDTF part becomes a solid carried into world space by
/// the fixture's full transform; without it the fixture is a placeholder cube.
/// When [fixtureType] is given, its wiring objects become [RigFixture]
/// connectors.
RigFixture buildRigFixture({
  required FixtureModel fixture,
  FixtureGeometryModel? geometry,
  FixtureTypeModel? fixtureType,
  required Color color,
  String? label,
  String? tooltip,
}) {
  final transform = fixture.transform;
  final parts = [
    for (final part in geometry?.parts ?? const <GeometryPartModel>[])
      if (part.corners.length == 8)
        RigSolid(
          OrientedBox.fromCorners(part.corners).transformedBy(transform),
          shape: _cylindricalPrimitives.contains(part.primitiveType)
              ? RigSolidShape.cylinder
              : RigSolidShape.box,
        ),
  ];

  return RigFixture(
    id: fixture.uid,
    parts: parts.isNotEmpty
        ? parts
        : [
            RigSolid(
              const OrientedBox.cube(
                center: Vector3.zero,
                size: kPlaceholderFixtureSizeMm,
              ).transformedBy(transform),
            ),
          ],
    color: color,
    labelAnchor: Vector3(fixture.x, fixture.y, fixture.z),
    connectors: [
      for (final wiringObject in fixtureType?.wiringObjects ?? const [])
        wiringObjectWorldPosition(fixture, wiringObject),
    ],
    label: label,
    tooltip: tooltip,
  );
}
