import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/cable_graph/cabling/chain_planner.dart';
import 'package:sidekick/cable_graph/cabling/fixture_ports.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_cabling_override.dart';

FixturePort _at(double x) =>
    FixturePort(position: Vector3(x, 0, 0), cableType: CableType.true1);

/// Plans three 1 m bars at x = 0, 1000, 2000 whose input sits [inputOffset]
/// from their centre and output at the opposite end.
List<String> _plan({
  required double inputOffset,
  ChainOrientation orientation = ChainOrientation.homeRunToFurthest,
}) {
  final bars = [
    for (var i = 0; i < 3; i++)
      FixtureModel(uid: 'b$i', sequence: i, x: i * 1000.0),
  ];

  return planChain(
    bars,
    inputOf: (bar) => _at(bar.x + inputOffset),
    outputOf: (bar) => _at(bar.x - inputOffset),
    orientation: orientation,
  ).map((bar) => bar.uid).toList();
}

void main() {
  test('a chain running with the flow keeps its order', () {
    expect(_plan(inputOffset: -500), ['b0', 'b1', 'b2']);
  });

  test('against the flow, the default homes to the furthest fixture', () {
    expect(_plan(inputOffset: 500), ['b2', 'b1', 'b0']);
  });

  test('against the flow, fold-back links keep the order', () {
    expect(
      _plan(inputOffset: 500, orientation: ChainOrientation.foldBackLinks),
      ['b0', 'b1', 'b2'],
    );
  });

  test('connectors at the centre never count as against the flow', () {
    expect(_plan(inputOffset: 0), ['b0', 'b1', 'b2']);
  });

  test('a difference within the tolerance keeps the order', () {
    // Each of the two links is 4 x offset shorter in reverse: 2 x 4 x 35 =
    // 280 mm is under the 300 mm tolerance...
    expect(_plan(inputOffset: 35), ['b0', 'b1', 'b2']);
    // ...while 2 x 4 x 40 = 320 mm is enough to reverse.
    expect(_plan(inputOffset: 40), ['b2', 'b1', 'b0']);
  });

  test('single fixtures are left alone', () {
    final solo = [FixtureModel(uid: 'solo')];

    expect(
      planChain(
        solo,
        inputOf: (_) => _at(500),
        outputOf: (_) => _at(-500),
        orientation: ChainOrientation.homeRunToFurthest,
      ),
      solo,
    );
  });
}
