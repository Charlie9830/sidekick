import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/data_selectors/select_cable_qtys.dart';
import 'package:sidekick/extension_methods/mvr_matrix_extensions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/fixture_type_cabling_override.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/location_override_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/truss_model.dart';
import 'package:sidekick/redux/models/wiring_object_model.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

const _loc = 'loc';

WiringObjectModel _wiring(
  String name,
  GDTFComponentType role,
  GDTFSignalType signal,
  GDTFConnectorType connector,
  double localX,
) => WiringObjectModel(
  name: name,
  componentType: role,
  signalType: signal,
  connectorType: connector,
  matrix: const MVRMatrix.identity().withTranslation(localX, 0, 0),
);

/// A 1 m bar with True1 and DMX in at its -X end and out at its +X end.
final _bar = FixtureTypeModel(
  uid: 'bar',
  wiringObjects: [
    _wiring(
      'Power In',
      GDTFComponentType.input,
      GDTFPredefinedSignalType.power,
      GDTFPredefinedConnectorType.powerconTrue1,
      -500,
    ),
    _wiring(
      'Power Out',
      GDTFComponentType.output,
      GDTFPredefinedSignalType.power,
      GDTFPredefinedConnectorType.powerconTrue1Top,
      500,
    ),
    _wiring(
      'DMX In',
      GDTFComponentType.input,
      GDTFPredefinedSignalType.dmx512,
      GDTFPredefinedConnectorType.xlr5,
      -500,
    ),
    _wiring(
      'DMX Out',
      GDTFComponentType.output,
      GDTFPredefinedSignalType.dmx512,
      GDTFPredefinedConnectorType.xlr5,
      500,
    ),
  ],
);

/// A fixture type with no GDTF wiring: AU10A and DMX at its centre.
final _spot = FixtureTypeModel(uid: 'spot');

FixtureModel _fixture(
  String uid, {
  required int sequence,
  required double x,
  String typeId = 'bar',
  String outlet = 'pm',
  String powerPatch = 'A',
  int universe = 1,
  double z = 0,
  MVRMatrix rotation = const MVRMatrix.identity(),
}) => FixtureModel(
  uid: uid,
  sequence: sequence,
  typeId: typeId,
  locationId: _loc,
  powerMultiOutletId: outlet,
  powerPatch: powerPatch,
  dmxAddress: DMXAddressModel(universe: universe, address: sequence),
  x: x,
  z: z,
  rotation: rotation,
);

PowerMultiOutletModel _outlet(String uid) => PowerMultiOutletModel(
  uid: uid,
  locationId: _loc,
  parentRack: const PowerMultiRackAssignment.unassigned(),
  desiredSpareCircuits: 0,
  children: const [],
);

CableGraph _build(
  List<FixtureModel> fixtures, {
  List<String> outlets = const ['pm'],
  List<CableModel> cables = const [],
  List<DataPatchModel> dataPatches = const [],
  Map<String, DataMultiModel> dataMultis = const {},
  Map<String, TrussModel> trusses = const {},
  LocationOverrideModel overrides = const LocationOverrideModel.none(),
}) => buildCableGraph(
  fixtures: {for (final fix in fixtures) fix.uid: fix},
  fixtureTypes: {'bar': _bar, 'spot': _spot},
  locations: {
    _loc: LocationModel(
      uid: _loc,
      color: const LabelColorModel.none(),
      overrides: overrides,
    ),
  },
  powerMultis: {for (final id in outlets) id: _outlet(id)},
  cables: {for (final cable in cables) cable.uid: cable},
  dataPatches: {for (final patch in dataPatches) patch.uid: patch},
  dataMultis: dataMultis,
  trusses: trusses,
);

Iterable<CableEdge> _edges(CableGraph graph, CableRunType runType) =>
    graph.edges.whereType<CableEdge>().where((e) => e.runType == runType);

/// Three 1 m True1 bars butted end to end: each output meets the next input.
final _barRow = [
  _fixture('b1', sequence: 1, x: 0),
  _fixture('b2', sequence: 2, x: 1000),
  _fixture('b3', sequence: 3, x: 2000),
];

void main() {
  group('links', () {
    test('butted True1 bars link with short True1 cables between '
        'connectors', () {
      final links = _edges(
        _build(_barRow),
        CableRunType.link,
      ).where((e) => e.type == CableType.true1).toList();

      expect(links, hasLength(2));
      // Output meets input: just the two 500 mm floor risers, not the 1 m
      // between bar centres.
      expect(links.first.euclidianLength, 1000);
      expect(links.first.length, 1);
      expect(links.first.fromPoint?.x, 500);
      expect(links.first.toPoint?.x, 500);
    });

    test('mismatched connectors link with the AU10A fallback', () {
      final links = _edges(
        _build([
          _fixture('b1', sequence: 1, x: 0),
          _fixture('s1', sequence: 2, x: 1000, typeId: 'spot'),
        ]),
        CableRunType.link,
      ).where((e) => e.type.signal == CableSignal.power);

      expect(links.single.type, CableType.au10a);
    });

    test('circuits are per outlet: a shared patch name does not link', () {
      final graph = _build(
        [
          _fixture('b1', sequence: 1, x: 0, outlet: 'pm1'),
          _fixture('b2', sequence: 2, x: 1000, outlet: 'pm2'),
        ],
        outlets: ['pm1', 'pm2'],
      );

      final powerLinks = _edges(
        graph,
        CableRunType.link,
      ).where((e) => e.type.signal == CableSignal.power);
      expect(powerLinks, isEmpty);
    });

    test('trussed links meet the truss at the connectors, not the centres', () {
      // A 4 m stick along X, 1 m above two butted bars.
      final graph = _build(
        [
          _fixture('b1', sequence: 1, x: 0, z: -1000),
          _fixture('b2', sequence: 2, x: 1000, z: -1000),
        ],
        trusses: {
          't': TrussModel(
            uid: 't',
            center: const Vector3(500, 0, 0),
            length: 4000,
            width: 300,
            height: 300,
          ),
        },
      );

      final link = _edges(
        graph,
        CableRunType.link,
      ).where((e) => e.type == CableType.true1).single;

      // Both connectors sit at x = 500, so the link is just the two risers up
      // to the top chord, with no run along the truss between bar centres.
      final riser = math.sqrt(150 * 150 + 1150 * 1150);
      expect(link.euclidianLength, closeTo(2 * riser, 1e-6));
    });

    test('unpatched fixtures are not chained', () {
      final graph = _build([
        _fixture('b1', sequence: 1, x: 0, powerPatch: ''),
        _fixture('b2', sequence: 2, x: 1000, powerPatch: ''),
      ]);

      final powerLinks = _edges(
        graph,
        CableRunType.link,
      ).where((e) => e.type.signal == CableSignal.power);
      expect(powerLinks, isEmpty);
    });
  });

  group('chain orientation', () {
    /// 180° about Z: each bar's input now faces +X, away from the header.
    final flipped = MVRMatrix([
      [-1.0, 0.0, 0.0],
      [0.0, -1.0, 0.0],
      [0.0, 0.0, 1.0],
      [0.0, 0.0, 0.0],
    ]);
    final flippedRow = [
      _fixture('b1', sequence: 1, x: 0, rotation: flipped),
      _fixture('b2', sequence: 2, x: 1000, rotation: flipped),
      _fixture('b3', sequence: 3, x: 2000, rotation: flipped),
    ];

    List<(String, String)> powerLinks(CableGraph graph) => [
      for (final link in _edges(graph, CableRunType.link))
        if (link.type.signal == CableSignal.power) (link.from, link.to),
    ];

    CableEdge powerRun(CableGraph graph) => _edges(
      graph,
      CableRunType.fixtureRun,
    ).singleWhere((e) => e.type.signal == CableSignal.power);

    test('by default, homes to the furthest bar and links back', () {
      final graph = _build(flippedRow);

      expect(powerRun(graph).to, 'b3');
      expect(powerLinks(graph), unorderedEquals([('b3', 'b2'), ('b2', 'b1')]));
      expect(_edges(graph, CableRunType.link).map((e) => e.length).toSet(), {
        1.0,
      });
    });

    test('fold-back links keep the home run on the nearest bar', () {
      final graph = _build(
        flippedRow,
        overrides: const LocationOverrideModel.none().withCabling(
          'bar',
          const FixtureTypeCablingOverride(
            orientation: ChainOrientation.foldBackLinks,
          ),
        ),
      );

      expect(powerRun(graph).to, 'b1');
      expect(powerLinks(graph), unorderedEquals([('b1', 'b2'), ('b2', 'b3')]));
      // Each link folds back 2 m from one bar's output to the next's input.
      expect(
        _edges(graph, CableRunType.link).map((e) => e.euclidianLength).toSet(),
        {3000.0},
      );
    });

    test('data chains follow the same orientation', () {
      final graph = _build(flippedRow);

      final dataLinks = [
        for (final link in _edges(graph, CableRunType.link))
          if (link.type.signal == CableSignal.data) (link.from, link.to),
      ];
      expect(dataLinks, unorderedEquals([('b3', 'b2'), ('b2', 'b1')]));
    });
  });

  group('location overrides', () {
    test('a power override swaps True1 for AU10A on links, runs and the '
        'lamp header, keeping connector positions', () {
      final graph = _build(
        _barRow,
        overrides: const LocationOverrideModel.none().withCabling(
          'bar',
          const FixtureTypeCablingOverride(power: CableType.au10a),
        ),
      );

      final powerEdges = graph.edges.whereType<CableEdge>().where(
        (e) =>
            e.type.signal == CableSignal.power &&
            e.runType != CableRunType.homeRun,
      );
      expect(powerEdges.map((e) => e.type).toSet(), {CableType.au10a});
      expect(powerEdges.every((e) => e.adaptorType == null), isTrue);

      final header = graph.getNode('pm') as PowerMultiHeaderNode;
      expect(header.lampHeaderType, CableType.socapexToAu10ALampHeader);

      final link = powerEdges.firstWhere((e) => e.runType == CableRunType.link);
      expect(link.fromPoint?.x, 500);
    });

    test('overrides only apply to their own fixture type', () {
      final graph = _build(
        _barRow,
        overrides: const LocationOverrideModel.none().withCabling(
          'spot',
          const FixtureTypeCablingOverride(power: CableType.nac3),
        ),
      );

      final header = graph.getNode('pm') as PowerMultiHeaderNode;
      expect(header.tail, CableType.true1);
    });
  });

  group('headers and fixture runs', () {
    test('a Socapex header feeding only True1 fixtures uses True1 tails', () {
      final graph = _build(_barRow);

      final header = graph.getNode('pm') as PowerMultiHeaderNode;
      expect(header.kind, HeaderKind.socapex);
      expect(header.lampHeaderType, CableType.socapexToTrue1LampHeader);

      final run = _edges(
        graph,
        CableRunType.fixtureRun,
      ).where((e) => e.type.signal == CableSignal.power).single;
      expect(run.type, CableType.true1);
      expect(run.adaptorType, isNull);
      expect(run.toPoint?.x, -500);
    });

    test('a 6-way header feeds True1 fixtures through an adaptor', () {
      final graph = _build(
        _barRow,
        cables: [
          CableModel(uid: 'c', type: CableType.wieland6way, outletId: 'pm'),
        ],
      );

      final header = graph.getNode('pm') as PowerMultiHeaderNode;
      expect(header.lampHeaderType, CableType.wieland6WayLampHeader);

      final qtys = selectCableQtysByLocationId(graph)[_loc]!;
      expect(
        qtys[CableQtyGroup(type: CableType.au10aToTrue1Adaptor, length: 0)],
        1,
      );
      expect(
        qtys[CableQtyGroup(type: CableType.wieland6WayLampHeader, length: 0)],
        1,
      );
      expect(
        _edges(graph, CableRunType.homeRun).single.type,
        CableType.wieland6way,
      );
    });

    test('a Socapex header with mixed inputs uses AU10A tails and adapts '
        'only the True1 circuit', () {
      final graph = _build([
        _fixture('b1', sequence: 1, x: 0, powerPatch: 'A'),
        _fixture('s1', sequence: 2, x: 3000, typeId: 'spot', powerPatch: 'B'),
      ]);

      final header = graph.getNode('pm') as PowerMultiHeaderNode;
      expect(header.lampHeaderType, CableType.socapexToAu10ALampHeader);

      final runs = {
        for (final run in _edges(
          graph,
          CableRunType.fixtureRun,
        ).where((e) => e.type.signal == CableSignal.power))
          run.to: run,
      };
      expect(runs['b1']!.adaptorType, CableType.au10aToTrue1Adaptor);
      expect(runs['s1']!.adaptorType, isNull);
    });

    test('a DMX line extended out of its sneak arrives straight', () {
      final graph = _build(
        [_fixture('b1', sequence: 1, x: 0)],
        dataPatches: [DataPatchModel(uid: 'dp', locationId: _loc, universe: 1)],
        dataMultis: {'dm': DataMultiModel(uid: 'dm', locationId: _loc)},
        cables: [
          CableModel(uid: 's', type: CableType.sneak, outletId: 'dm'),
          CableModel(
            uid: 'd1',
            type: CableType.dmx,
            outletId: 'dp',
            parentMultiId: 's',
          ),
          CableModel(
            uid: 'd2',
            type: CableType.dmx,
            outletId: 'dp',
            upstreamId: 'd1',
          ),
        ],
      );

      expect(graph.nodes.whereType<DataMultiHeaderNode>(), isEmpty);
      expect(graph.getNode(_loc)!.edges.map((e) => e.to), contains('dp'));
    });
  });
}
