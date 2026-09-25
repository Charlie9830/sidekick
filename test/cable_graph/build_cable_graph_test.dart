import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/data_selectors/select_cable_qtys.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/truss_model.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

const _locationId = 'loc';
const _powerMultiId = 'pm1';
const _dataPatchId = 'dp1';
const _dataMultiId = 'dm1';

FixtureModel _fixture(
  String uid, {
  required int sequence,
  required double x,
  double z = 0,
  String powerPatch = 'A',
}) => FixtureModel(
  uid: uid,
  sequence: sequence,
  typeId: 'type',
  locationId: _locationId,
  powerPatch: powerPatch,
  powerMultiOutletId: _powerMultiId,
  dmxAddress: DMXAddressModel(universe: 1, address: sequence),
  x: x,
  z: z,
);

TrussModel _truss(String uid, double centreX) => TrussModel(
  uid: uid,
  center: Vector3(centreX, 0, 0),
  length: 4000,
  width: 300,
  height: 300,
);

CableGraph _build({
  required Map<String, FixtureModel> fixtures,
  Map<String, TrussModel> trusses = const {},
  bool breakAtTrussJoins = true,
}) {
  return buildCableGraph(
    fixtures: fixtures,
    fixtureTypes: {'type': FixtureTypeModel(uid: 'type')},
    locations: {
      _locationId: LocationModel(
        uid: _locationId,
        color: const LabelColorModel.none(),
        breakAtTrussJoins: breakAtTrussJoins,
      ),
    },
    powerMultis: {
      _powerMultiId: PowerMultiOutletModel(
        uid: _powerMultiId,
        locationId: _locationId,
        parentRack: const PowerMultiRackAssignment.unassigned(),
        desiredSpareCircuits: 0,
        children: const [],
      ),
    },
    dataPatches: {
      _dataPatchId: DataPatchModel(
        uid: _dataPatchId,
        locationId: _locationId,
        universe: 1,
      ),
    },
    dataMultis: {
      _dataMultiId: DataMultiModel(uid: _dataMultiId, locationId: _locationId),
    },
    cables: {
      'sneak': CableModel(
        uid: 'sneak',
        type: CableType.sneak,
        outletId: _dataMultiId,
      ),
      'dmx': CableModel(
        uid: 'dmx',
        type: CableType.dmx,
        outletId: _dataPatchId,
        parentMultiId: 'sneak',
      ),
    },
    trusses: trusses,
  );
}

Iterable<CableEdge> _cableEdges(CableGraph graph, CableRunType runType) =>
    graph.edges.whereType<CableEdge>().where((e) => e.runType == runType);

void main() {
  group('floor rig (no trusses)', () {
    // Three fixtures 2 m apart on the floor. f1 and f2 share power patch A,
    // f3 is alone on patch B; all three share universe 1.
    final graph = _build(
      fixtures: {
        'f1': _fixture('f1', sequence: 1, x: 0),
        'f2': _fixture('f2', sequence: 2, x: 2000),
        'f3': _fixture('f3', sequence: 3, x: 4000, powerPatch: 'B'),
      },
    );

    test('power links chain fixtures within a patch as AU10A', () {
      final links = _cableEdges(
        graph,
        CableRunType.link,
      ).where((e) => e.type == CableType.au10a).toList();

      expect(links, hasLength(1));
      expect((links.single.from, links.single.to), ('f1', 'f2'));
      // 500 riser + 2000 horizontal + 500 riser.
      expect(links.single.euclidianLength, 3000);
      expect(links.single.length, 3);
    });

    test('data links chain every fixture in a universe as DMX', () {
      final links = _cableEdges(
        graph,
        CableRunType.link,
      ).where((e) => e.type == CableType.dmx).map((e) => (e.from, e.to));

      expect(links, unorderedEquals([('f1', 'f2'), ('f2', 'f3')]));
    });

    test('power header feeds the first fixture of each patch', () {
      final runs = _cableEdges(graph, CableRunType.fixtureRun)
          .where((e) => e.type == CableType.au10a)
          .map((e) => (e.from, e.to, e.length));

      // Header sits on f1: f1 is a 500 mm riser away, f3 is 4 m + riser.
      expect(
        runs,
        unorderedEquals([
          (_powerMultiId, 'f1', 1.0),
          (_powerMultiId, 'f3', 5.0),
        ]),
      );
    });

    test('location feeds the power multi with a Socapex home run', () {
      final homeRuns = _cableEdges(graph, CableRunType.homeRun).toList();

      expect(homeRuns, hasLength(1));
      expect(homeRuns.single.type, CableType.socapex);
      expect(homeRuns.single.to, _powerMultiId);
      expect(homeRuns.single.length, 2);
    });

    test('data patch under a sneak hangs off the data multi header', () {
      expect(graph.getNode(_dataMultiId), isA<DataMultiHeaderNode>());
      final patch = graph.getNode(_dataPatchId) as DataPatchHeaderNode;
      expect(patch.parentMultiOutletId, _dataMultiId);

      final location = graph.getNode(_locationId)!;
      expect(location.edges.map((e) => e.to), contains(_dataMultiId));
      expect(location.edges.map((e) => e.to), isNot(contains(_dataPatchId)));
    });

    test('walking from the location reaches every node', () {
      final walked = graph.walk(graph.getNode(_locationId)!).map((n) => n.id);

      expect(walked.toSet(), graph.nodes.map((n) => n.id).toSet());
    });

    test('cable quantities include runs and implied lamp headers', () {
      final qtys = selectCableQtysByLocationId(graph)[_locationId]!;

      expect(qtys, {
        CableQtyGroup(type: CableType.au10a, length: 3): 1,
        CableQtyGroup(type: CableType.au10a, length: 1): 1,
        CableQtyGroup(type: CableType.au10a, length: 5): 1,
        CableQtyGroup(type: CableType.dmx, length: 3): 2,
        CableQtyGroup(type: CableType.dmx, length: 1): 1,
        CableQtyGroup(type: CableType.socapex, length: 2): 1,
        CableQtyGroup(type: CableType.socapexToAu10ALampHeader, length: 0): 1,
        CableQtyGroup(type: CableType.sneakLampHeader, length: 0): 1,
      });
    });
  });

  group('trussed rig', () {
    // Two 4 m sticks joined end to end at x = 0, one fixture under each.
    final fixtures = {
      'f1': _fixture('f1', sequence: 1, x: -1000, z: -1000),
      'f2': _fixture('f2', sequence: 2, x: 1000, z: -1000),
    };
    final trusses = {'t1': _truss('t1', -2000), 't2': _truss('t2', 2000)};

    test('links crossing a join are split at a break node', () {
      final graph = _build(fixtures: fixtures, trusses: trusses);

      final breaks = graph.nodes.whereType<TrussBreakNode>().toList();
      // One break for the power link, one for the data link.
      expect(breaks, hasLength(2));
      expect(_cableEdges(graph, CableRunType.link), hasLength(4));
    });

    test('links are not split when breakAtTrussJoins is off', () {
      final broken = _build(fixtures: fixtures, trusses: trusses);
      final whole = _build(
        fixtures: fixtures,
        trusses: trusses,
        breakAtTrussJoins: false,
      );

      expect(whole.nodes.whereType<TrussBreakNode>(), isEmpty);
      final wholeLinks = _cableEdges(whole, CableRunType.link).toList();
      expect(wholeLinks, hasLength(2));

      // The unbroken run measures the same as its broken segments combined.
      double totalFor(CableGraph graph, CableType type) =>
          _cableEdges(graph, CableRunType.link)
              .where((e) => e.type == type)
              .fold(0.0, (sum, e) => sum + e.euclidianLength);
      expect(
        totalFor(whole, CableType.au10a),
        closeTo(totalFor(broken, CableType.au10a), 1e-6),
      );
    });
  });
}
