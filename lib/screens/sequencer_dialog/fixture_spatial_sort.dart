import 'package:sidekick/cable_graph/view_projection.dart';
import 'package:sidekick/redux/models/fixture_model.dart';

/// The axis used to spatially order fixtures in the sequencer.
enum FixtureSortAxis {
  /// Preserve the order the fixtures were selected in (no coord dependency).
  selectionOrder,

  /// Order by horizontal position (left → right in the plan view).
  x,

  /// Order by vertical position (top → bottom in the plan view).
  y,
}

const ViewProjection _kProjection = OrthogonalView.top;

/// Whether [fixtures] carry real world coordinates worth sorting or plotting.
///
/// Fixtures imported without matrix data (e.g. a non-MVR patch) all sit at the
/// origin, so spatial features fall back to the selection order instead.
bool hasUsableCoords(Iterable<FixtureModel> fixtures) =>
    fixtures.any((fixture) => fixture.hasMatrixData);

/// Returns [fixtures] ordered along [axis] using the plan-view projection.
///
/// The other axis is used as a stable tie-break so fixtures sharing a primary
/// coordinate keep a predictable order. [FixtureSortAxis.selectionOrder]
/// returns a copy in the original order (optionally reversed).
List<FixtureModel> sortFixturesSpatially(
  List<FixtureModel> fixtures,
  FixtureSortAxis axis, {
  bool descending = false,
}) {
  if (axis == FixtureSortAxis.selectionOrder) {
    final ordered = fixtures.toList();
    return descending ? ordered.reversed.toList() : ordered;
  }

  final sorted = fixtures.toList()
    ..sort((a, b) {
      final pa = _kProjection.project(a.x, a.y, a.z);
      final pb = _kProjection.project(b.x, b.y, b.z);

      final (primaryA, secondaryA) = axis == FixtureSortAxis.x
          ? (pa.dx, pa.dy)
          : (pa.dy, pa.dx);
      final (primaryB, secondaryB) = axis == FixtureSortAxis.x
          ? (pb.dx, pb.dy)
          : (pb.dy, pb.dx);

      final primary = primaryA.compareTo(primaryB);
      return primary != 0 ? primary : secondaryA.compareTo(secondaryB);
    });

  return descending ? sorted.reversed.toList() : sorted;
}
