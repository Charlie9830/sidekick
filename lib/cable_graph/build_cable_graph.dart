import 'package:collection/collection.dart';

import 'package:sidekick/cable_graph/cabling/cable_router.dart';
import 'package:sidekick/cable_graph/cabling/cable_stock.dart';
import 'package:sidekick/cable_graph/cabling/chain_planner.dart';
import 'package:sidekick/cable_graph/cabling/connector_cable_map.dart';
import 'package:sidekick/cable_graph/cabling/fixture_ports.dart';
import 'package:sidekick/cable_graph/cabling/header_resolver.dart';
import 'package:sidekick/cable_graph/graph/cable_graph.dart';
import 'package:sidekick/cable_graph/graph/edges.dart';
import 'package:sidekick/cable_graph/graph/nodes.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/truss_model.dart';

/// Builds the breakout cable graph for every non-hybrid location.
///
/// Each location gets a [LocationNode] root feeding its multi headers, which in
/// turn feed the first fixture of each circuit and universe; fixtures are then
/// linked to the next fixture in sequence. Cable types come from each
/// fixture's connectors and each outlet's loom chain; [defaultPowerMulti] is
/// the power multicore assumed for outlets with no cables yet.
CableGraph buildCableGraph({
  required Map<String, FixtureModel> fixtures,
  required Map<String, FixtureTypeModel> fixtureTypes,
  required Map<String, PowerMultiOutletModel> powerMultis,
  required Map<String, CableModel> cables,
  required Map<String, LocationModel> locations,
  required Map<String, DataMultiModel> dataMultis,
  required Map<String, DataPatchModel> dataPatches,
  Map<String, TrussModel> trusses = const {},
  CableType defaultPowerMulti = CableType.socapex,
}) {
  final context = _GraphContext(
    fixtureTypes: fixtureTypes,
    router: CableRouter.build(
      trusses: trusses.values,
      fixtures: fixtures.values,
    ),
    headers: HeaderResolver(cables, defaultPowerMulti: defaultPowerMulti),
    ports: {
      for (final fix in fixtures.values)
        fix.uid: _resolvePorts(fix, fixtureTypes, locations),
    },
  );

  return CableGraph([
    for (final location in locations.values.where((loc) => !loc.isHybrid))
      ..._LocationBuilder(
        context,
        location: location,
        fixtures: fixtures.values
            .where((fix) => fix.locationId == location.uid)
            .toList(),
      ).build(
        powerMultis: powerMultis.values.where(
          (multi) => multi.locationId == location.uid,
        ),
        dataPatches: dataPatches.values.where(
          (patch) => patch.locationId == location.uid,
        ),
        dataMultis: dataMultis,
      ),
  ]);
}

/// Resolves [fixture]'s ports, applying its location's cabling override for
/// its fixture type.
FixturePorts _resolvePorts(
  FixtureModel fixture,
  Map<String, FixtureTypeModel> fixtureTypes,
  Map<String, LocationModel> locations,
) {
  final override = locations[fixture.locationId]?.overrides.getCabling(
    fixture.typeId,
  );

  return resolveFixturePorts(
    fixture,
    fixtureTypes[fixture.typeId]!,
    powerOverride: override?.power,
    dataOverride: override?.data,
  );
}

/// Everything resolved once for the whole rig and shared by every location.
class _GraphContext {
  final Map<String, FixtureTypeModel> fixtureTypes;
  final CableRouter router;
  final HeaderResolver headers;
  final Map<String, FixturePorts> ports;

  _GraphContext({
    required this.fixtureTypes,
    required this.router,
    required this.headers,
    required this.ports,
  });
}

/// The first cable edge of a run, plus the break nodes that own the rest of it.
typedef _Run = ({CableEdge head, List<TrussBreakNode> breakNodes});

class _LocationBuilder {
  final _GraphContext context;
  final LocationModel location;
  final List<FixtureModel> fixtures;

  _LocationBuilder(
    this.context, {
    required this.location,
    required this.fixtures,
  });

  /// The first fixture by sequence: where the location's cabling arrives.
  late final Vector3 _origin = fixtures.isEmpty
      ? Vector3.zero
      : _positionOf(fixtures.sorted().first);

  /// Each power circuit, keyed by (outlet, patch), in cabling order.
  late final Map<(String, String), List<FixtureModel>> _powerChains =
      _powerCircuits(
        fixtures,
      ).map((key, circuit) => MapEntry(key, _plan(circuit, CableSignal.power)));

  /// Each universe's fixtures, in cabling order.
  late final Map<int, List<FixtureModel>> _dataChains = fixtures
      .groupListsBy((fix) => fix.dmxAddress.universe)
      .map(
        (universe, chain) => MapEntry(universe, _plan(chain, CableSignal.data)),
      );

  List<Node> build({
    required Iterable<PowerMultiOutletModel> powerMultis,
    required Iterable<DataPatchModel> dataPatches,
    required Map<String, DataMultiModel> dataMultis,
  }) {
    final links = [
      ..._chainLinks(_powerChains.values, CableSignal.power),
      ..._chainLinks(_dataChains.values, CableSignal.data),
    ];
    final powerHeaders = powerMultis.map(_powerMultiHeader).toList();
    final patchHeaders = dataPatches.map(_dataPatchHeader).toList();
    final dataMultiHeaders = _dataMultiHeaders(patchHeaders, dataMultis);

    return [
      ..._fixtureNodes(links.map((run) => run.head)),
      for (final run in links) ...run.breakNodes,
      ...powerHeaders,
      ...patchHeaders,
      ...dataMultiHeaders,
      LocationNode(
        locationId: location.uid,
        position: _origin,
        edges: {
          ...powerHeaders.map(_homeRun),
          ...dataMultiHeaders.map(
            (node) => LogicalEdge(from: location.uid, to: node.id),
          ),
          ...patchHeaders
              .where((node) => node.parentMultiOutletId.isEmpty)
              .map((node) => LogicalEdge(from: location.uid, to: node.id)),
        },
      ),
    ];
  }

  List<FixtureNode> _fixtureNodes(Iterable<CableEdge> linkHeads) {
    final edgesByFixtureId = linkHeads.groupListsBy((edge) => edge.from);

    return [
      for (final fix in fixtures)
        FixtureNode(
          id: fix.uid,
          position: _positionOf(fix),
          locationId: fix.locationId,
          type: context.fixtureTypes[fix.typeId]!,
          edges: {...?edgesByFixtureId[fix.uid]},
        ),
    ];
  }

  /// Orders [chain] for cabling its [signal], by sequence and then by the
  /// orientation set for the chain's first fixture type.
  List<FixtureModel> _plan(List<FixtureModel> chain, CableSignal signal) {
    final ordered = chain.sorted();

    return planChain(
      ordered,
      inputOf: (fix) => _portsOf(fix).inputFor(signal),
      outputOf: (fix) => _portsOf(fix).outputFor(signal),
      orientation: location.overrides
          .getCabling(ordered.first.typeId)
          .orientation,
    );
  }

  /// Links each fixture of every planned chain to the next, from its [signal]
  /// output to the next fixture's input.
  ///
  /// The link uses the connectors' shared cable, or the [signal]'s fallback
  /// cable when they differ.
  Iterable<_Run> _chainLinks(
    Iterable<List<FixtureModel>> chains,
    CableSignal signal,
  ) sync* {
    for (final ordered in chains) {
      for (var i = 0; i < ordered.length - 1; i++) {
        final from = _portsOf(ordered[i]).outputFor(signal);
        final to = _portsOf(ordered[i + 1]).inputFor(signal);
        final type = from.cableType == to.cableType
            ? from.cableType
            : fallbackCableType(signal);

        yield _linkRun(
          (fixtureId: ordered[i].uid, position: from.position),
          (fixtureId: ordered[i + 1].uid, position: to.position),
          type,
        );
      }
    }
  }

  /// Builds the cable edge(s) for a fixture-to-fixture link, splitting at any
  /// truss joins the run crosses.
  ///
  /// When the location does not break at truss joins, or the run crosses none,
  /// the whole run is one edge whose length follows the truss chord.
  _Run _linkRun(RoutePoint from, RoutePoint to, CableType type) {
    final split = context.router.splitLink(from: from, to: to);
    final stock = type.stockLengths;

    CableEdge edge(
      String fromId,
      String toId,
      double length, {
      Vector3? fromPoint,
      Vector3? toPoint,
    }) => CableEdge(
      from: fromId,
      to: toId,
      euclidianLength: length,
      length: roundUpToStock(length, stock),
      locationId: location.uid,
      runType: CableRunType.link,
      type: type,
      fromPoint: fromPoint,
      toPoint: toPoint,
    );

    if (!location.breakAtTrussJoins || !split.hasBreaks) {
      return (
        head: edge(
          from.fixtureId,
          to.fixtureId,
          split.segmentLengths.sum,
          fromPoint: from.position,
          toPoint: to.position,
        ),
        breakNodes: const [],
      );
    }

    // from -> break_0 -> ... -> break_n -> to. The cable type is part of the
    // break id so a power and a data link between the same pair don't collide.
    final ids = [
      from.fixtureId,
      for (var i = 0; i < split.breakPoints.length; i++)
        '${from.fixtureId}~${type.name}brk$i~${to.fixtureId}',
      to.fixtureId,
    ];
    final lastIndex = ids.length - 2;
    final edges = [
      for (var i = 0; i <= lastIndex; i++)
        edge(
          ids[i],
          ids[i + 1],
          split.segmentLengths[i],
          fromPoint: i == 0 ? from.position : null,
          toPoint: i == lastIndex ? to.position : null,
        ),
    ];

    return (
      head: edges.first,
      breakNodes: [
        for (var i = 0; i < split.breakPoints.length; i++)
          TrussBreakNode(
            id: ids[i + 1],
            locationId: location.uid,
            position: split.breakPoints[i],
            edges: {edges[i + 1]},
          ),
      ],
    );
  }

  PowerMultiHeaderNode _powerMultiHeader(PowerMultiOutletModel outlet) {
    final downstream = fixtures
        .where((fix) => fix.powerMultiOutletId == outlet.uid)
        .toList();
    final position = _powerHeaderPosition(downstream);
    final firstInEachCircuit = [
      for (final MapEntry(key: (outletId, _), value: chain)
          in _powerChains.entries)
        if (outletId == outlet.uid) chain.first,
    ];

    final kind = context.headers.powerHeaderFor(outlet.uid);
    final tail = kind.tailFor(
      firstInEachCircuit.map((fix) => _portsOf(fix).powerIn.cableType),
    );

    return PowerMultiHeaderNode(
      id: outlet.uid,
      outletName: outlet.name,
      kind: kind,
      tail: tail,
      lampHeaderType: kind.lampHeaderFor(tail)!,
      locationId: outlet.locationId,
      position: position,
      edges: {
        for (final fix in firstInEachCircuit)
          _fixtureRun(outlet.uid, position, fix, tail, _portsOf(fix).powerIn),
      },
    );
  }

  DataPatchHeaderNode _dataPatchHeader(DataPatchModel outlet) {
    final header = context.headers.dataHeaderFor(outlet.uid);
    final firstFixture = _dataChains[outlet.universe]?.first;

    return DataPatchHeaderNode(
      id: outlet.uid,
      outletName: outlet.name,
      universe: outlet.universe,
      parentMultiOutletId: header.parentMultiOutletId,
      locationId: outlet.locationId,
      position: _origin,
      edges: {
        if (firstFixture case final fix?)
          _fixtureRun(
            outlet.uid,
            _origin,
            fix,
            header.kind.tailFor([_portsOf(fix).dataIn.cableType]),
            _portsOf(fix).dataIn,
          ),
      },
    );
  }

  List<DataMultiHeaderNode> _dataMultiHeaders(
    List<DataPatchHeaderNode> patchHeaders,
    Map<String, DataMultiModel> dataMultis,
  ) {
    return [
      for (final MapEntry(key: multiId, value: children)
          in patchHeaders.groupListsBy((n) => n.parentMultiOutletId).entries)
        if (dataMultis[multiId] case final multi?)
          DataMultiHeaderNode(
            id: multiId,
            outletName: multi.name,
            locationId: multi.locationId,
            position: _origin,
            edges: {
              for (final child in children)
                LogicalEdge(from: multiId, to: child.id),
            },
          ),
    ];
  }

  /// A [tail] cable from a header at [from] to [input] on the first fixture of
  /// a circuit or universe, with an adaptor if the tail doesn't fit the input.
  CableEdge _fixtureRun(
    String headerId,
    Vector3 from,
    FixtureModel fixture,
    CableType tail,
    FixturePort input,
  ) {
    final length = context.router.homeRunLength(
      from: from,
      to: (fixtureId: fixture.uid, position: input.position),
    );

    return CableEdge(
      from: headerId,
      to: fixture.uid,
      euclidianLength: length,
      length: roundUpToStock(length, tail.stockLengths),
      locationId: location.uid,
      runType: CableRunType.fixtureRun,
      type: tail,
      toPoint: input.position,
      adaptorType: adaptorFor(tail: tail, input: input.cableType),
    );
  }

  /// The multicore from the location's arrival point to a power multi header.
  CableEdge _homeRun(PowerMultiHeaderNode header) {
    final length = _origin.distanceTo(header.position);

    return CableEdge(
      from: location.uid,
      to: header.id,
      euclidianLength: length,
      length: roundUpToStock(length, header.cableType.stockLengths),
      locationId: location.uid,
      runType: CableRunType.homeRun,
      type: header.cableType,
    );
  }

  FixturePorts _portsOf(FixtureModel fixture) => context.ports[fixture.uid]!;
}

/// Groups [fixtures] into power circuits: fixtures sharing both a power multi
/// outlet and a power patch. Unpatched fixtures belong to no circuit.
Map<(String, String), List<FixtureModel>> _powerCircuits(
  Iterable<FixtureModel> fixtures,
) => fixtures
    .where((fix) => fix.powerPatch.isNotEmpty)
    .groupListsBy((fix) => (fix.powerMultiOutletId, fix.powerPatch));

/// Places a power header on the fixture with the most others within 1 m of it,
/// preferring the earliest on a tie.
Vector3 _powerHeaderPosition(List<FixtureModel> fixtures) {
  if (fixtures.isEmpty) return Vector3.zero;

  int neighbours(FixtureModel fix) => fixtures
      .where((other) => other == fix || other.distanceTo(fix) <= 1000)
      .length;

  var best = fixtures.first;
  var bestScore = neighbours(best);
  for (final fix in fixtures.skip(1)) {
    final score = neighbours(fix);
    if (score > bestScore) {
      best = fix;
      bestScore = score;
    }
  }

  return _positionOf(best);
}

Vector3 _positionOf(FixtureModel fix) => Vector3(fix.x, fix.y, fix.z);
