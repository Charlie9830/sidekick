import 'package:sidekick/cable_graph/cabling/fixture_ports.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_cabling_override.dart';

/// How much shorter (mm) linking a chain in reverse must be before the chain
/// counts as running against the flow.
const kOrientationToleranceMm = 300.0;

/// Orders a chain of fixtures for cabling: the home run feeds the first
/// fixture returned, and each fixture links to the next.
///
/// [ordered] is the chain in patch order. When linking it in that order
/// (each output to the next fixture's input) is at least
/// [kOrientationToleranceMm] longer than linking it in reverse, the chain runs
/// against the flow and [orientation] decides whether to reverse it
/// ([ChainOrientation.homeRunToFurthest]) or keep it
/// ([ChainOrientation.foldBackLinks]).
List<FixtureModel> planChain(
  List<FixtureModel> ordered, {
  required FixturePort Function(FixtureModel fixture) inputOf,
  required FixturePort Function(FixtureModel fixture) outputOf,
  required ChainOrientation orientation,
}) {
  double linkTotal(List<FixtureModel> chain) => [
    for (var i = 0; i < chain.length - 1; i++)
      outputOf(chain[i]).position.distanceTo(inputOf(chain[i + 1]).position),
  ].fold(0.0, (sum, length) => sum + length);

  final reversed = ordered.reversed.toList();
  final isAgainstFlow =
      linkTotal(reversed) < linkTotal(ordered) - kOrientationToleranceMm;

  return isAgainstFlow && orientation == ChainOrientation.homeRunToFurthest
      ? reversed
      : ordered;
}
