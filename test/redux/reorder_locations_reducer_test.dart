import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/multi_outlet_asserts.dart';
import 'package:sidekick/perform_power_patch.dart';
import 'package:sidekick/redux/actions/location_sync_actions.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/reducers/fixture_state/assert_cable_state.dart';
import 'package:sidekick/redux/reducers/fixture_state/location_reducer.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';
import 'package:sidekick/serialization/project_file_model.dart';

void main() {
  group('ReorderLocations reducer', () {
    // Original order is [locA, locB, locC]. Every test reorders to the
    // permutation below unless it is exercising the validation guard.
    const originalOrder = ['locA', 'locB', 'locC'];
    const newOrder = ['locC', 'locA', 'locB'];

    late FixtureState state;

    setUp(() {
      state = _buildPopulatedState();
    });

    FixtureState reorder(List<String> ids) =>
        reduceLocationActions(state, ReorderLocations(ids))!;

    test('locations map keys come out in the requested order', () {
      // Arrange / Act.
      final result = reorder(newOrder);

      // Assert.
      expect(result.locations.keys.toList(), newOrder);
      expect(
        state.locations.keys.toList(),
        originalOrder,
        reason: 'Original state must not be mutated.',
      );
    });

    test('every dependent map iterates grouped by the new location order', () {
      // Act.
      final result = reorder(newOrder);

      // Assert - each collection is grouped, in the new location order.
      _expectGroupedByOrder(
        result.fixtures.values.map((f) => f.locationId).toList(),
        newOrder,
      );
      _expectGroupedByOrder(
        result.powerMultiOutlets.values.map((o) => o.locationId).toList(),
        newOrder,
      );
      _expectGroupedByOrder(
        result.dataMultis.values.map((o) => o.locationId).toList(),
        newOrder,
      );
      _expectGroupedByOrder(
        result.dataPatches.values.map((o) => o.locationId).toList(),
        newOrder,
      );
      _expectGroupedByOrder(
        result.hoistMultis.values.map((o) => o.locationId).toList(),
        newOrder,
      );
      _expectGroupedByOrder(
        result.hoists.values.map((h) => h.locationId).toList(),
        newOrder,
      );

      // Cables carry no locationId; their canonical order is derived purely
      // from the (already re-sorted) outlet maps. Proving the state holds
      // exactly what assertCableState produces from those maps proves the
      // cables are grouped correctly.
      final expectedCables = assertCableState(
        cables: result.cables,
        powerMultiOutlets: result.powerMultiOutlets,
        dataMultis: result.dataMultis,
        dataPatches: result.dataPatches,
        hoistMultis: result.hoistMultis,
        hoistOutlets: result.hoists,
      );
      expect(result.cables.keys.toList(), expectedCables.keys.toList());
    });

    test('power multis and fixture patch data equal a direct performPowerPatch '
        'over the reordered locations', () {
      // Arrange - the declarative expectation: a fresh patch over the new
      // order, fed the exact same inputs the reducer uses.
      final newLocations = _reorderMap(state.locations, newOrder);
      final expectedPatch = performPowerPatch(
        fixtures: state.fixtures,
        fixtureTypes: state.fixtureTypes,
        powerMultiOutlets: state.powerMultiOutlets,
        locations: newLocations,
        maxSequenceBreak: state.maxSequenceBreak,
        balanceTolerance: state.balanceTolerance,
        powerRacks: state.powerRacks,
        fixtureTypePools: state.fixtureTypePools,
      );
      final expectedFixtures = FixtureModel.sort(
        expectedPatch.fixtures,
        newLocations,
      );

      // Act.
      final result = reorder(newOrder);

      // Assert - power multis identical (uids, order and full contents).
      expect(
        result.powerMultiOutlets.keys.toList(),
        expectedPatch.powerMultiOutlets.keys.toList(),
      );
      for (final uid in expectedPatch.powerMultiOutlets.keys) {
        expect(
          result.powerMultiOutlets[uid]!.toJson(),
          expectedPatch.powerMultiOutlets[uid]!.toJson(),
        );
      }

      // Assert - fixture patch data (powerPatch + powerMultiOutletId) matches.
      expect(result.fixtures.keys.toList(), expectedFixtures.keys.toList());
      for (final uid in expectedFixtures.keys) {
        expect(result.fixtures[uid]!.toJson(), expectedFixtures[uid]!.toJson());
      }
    });

    test('non-power content models are untouched, only map order changes', () {
      // Act.
      final result = reorder(newOrder);

      // Assert - the set of models is identical (same uids), and each model's
      // serialized content is unchanged. Only the iteration order differs.
      _expectSameModels(state.dataMultis, result.dataMultis, (m) => m.toJson());
      _expectSameModels(
        state.dataPatches,
        result.dataPatches,
        (m) => m.toJson(),
      );
      _expectSameModels(
        state.hoistMultis,
        result.hoistMultis,
        (m) => m.toJson(),
      );
      _expectSameModels(state.hoists, result.hoists, (m) => m.toJson());
    });

    test('hoist relative order within each location is preserved', () {
      // Act.
      final result = reorder(newOrder);

      // Assert - within every location the hoists keep their original relative
      // order, and their names are untouched.
      for (final locationId in originalOrder) {
        final before = state.hoists.values
            .where((h) => h.locationId == locationId)
            .toList();
        final after = result.hoists.values
            .where((h) => h.locationId == locationId)
            .toList();

        expect(
          after.map((h) => h.uid).toList(),
          before.map((h) => h.uid).toList(),
        );
        expect(
          after.map((h) => h.name).toList(),
          before.map((h) => h.name).toList(),
        );
      }
    });

    test(
      'a stale or incomplete id list returns the identical state instance',
      () {
        // A missing id (permutation is not exactly the key set).
        final missing = reduceLocationActions(
          state,
          ReorderLocations(['locC', 'locA']),
        );
        expect(identical(missing, state), isTrue);

        // An extra, unknown id.
        final extra = reduceLocationActions(
          state,
          ReorderLocations(['locC', 'locA', 'locB', 'locGhost']),
        );
        expect(identical(extra, state), isTrue);

        // A duplicate id (right length, wrong set).
        final duplicate = reduceLocationActions(
          state,
          ReorderLocations(['locC', 'locA', 'locA']),
        );
        expect(identical(duplicate, state), isTrue);
      },
    );

    test('round-trip serialize then deserialize preserves the new order', () {
      // Arrange.
      final result = reorder(newOrder);

      // Act - mirror serializeProjectFile / OpenProject: write every map as a
      // values list, then rebuild the state from the parsed JSON.
      final projectFile = _toProjectFile(result);
      final roundTripped = ProjectFileModel.fromJson(
        projectFile.toJson(),
      ).toFixtureState();

      // Assert - order survives the round-trip for every dependent map.
      expect(roundTripped.locations.keys.toList(), newOrder);
      expect(
        roundTripped.fixtures.keys.toList(),
        result.fixtures.keys.toList(),
      );
      expect(
        roundTripped.powerMultiOutlets.keys.toList(),
        result.powerMultiOutlets.keys.toList(),
      );
      expect(
        roundTripped.dataMultis.keys.toList(),
        result.dataMultis.keys.toList(),
      );
      expect(
        roundTripped.dataPatches.keys.toList(),
        result.dataPatches.keys.toList(),
      );
      expect(
        roundTripped.hoistMultis.keys.toList(),
        result.hoistMultis.keys.toList(),
      );
      expect(roundTripped.hoists.keys.toList(), result.hoists.keys.toList());
      expect(roundTripped.cables.keys.toList(), result.cables.keys.toList());
    });

    test(
      'hoists.values match the location-grouped flattening (sidebar index)',
      () {
        // Regression guard for selectSidebarItems' global index arithmetic,
        // which indexes into the raw hoists.values list using per-location
        // offsets accumulated in locations order. That only holds if the hoists
        // map iterates grouped by location order.
        final result = reorder(newOrder);

        final flattenedByLocationOrder = newOrder
            .expand(
              (locationId) =>
                  result.hoists.values.where((h) => h.locationId == locationId),
            )
            .map((h) => h.uid)
            .toList();

        expect(
          result.hoists.values.map((h) => h.uid).toList(),
          flattenedByLocationOrder,
        );
      },
    );
  });
}

/// Asserts [actualLocationIds] is contiguously grouped, with the groups
/// appearing in [newOrder]. Reconstructs the expected sequence by walking the
/// new order and collecting every matching entry; an interleaved (ungrouped)
/// actual sequence will not match.
void _expectGroupedByOrder(
  List<String> actualLocationIds,
  List<String> newOrder,
) {
  final expected = newOrder
      .expand((locationId) => actualLocationIds.where((id) => id == locationId))
      .toList();
  expect(actualLocationIds, expected);
}

/// Asserts [before] and [after] hold the same models by uid, with identical
/// serialized content regardless of iteration order.
void _expectSameModels<T>(
  Map<String, T> before,
  Map<String, T> after,
  String Function(T) encode,
) {
  expect(after.keys.toSet(), before.keys.toSet());
  for (final uid in before.keys) {
    expect(encode(after[uid] as T), encode(before[uid] as T));
  }
}

Map<String, LocationModel> _reorderMap(
  Map<String, LocationModel> locations,
  List<String> order,
) => Map<String, LocationModel>.fromEntries(
  order.map((id) => MapEntry(id, locations[id]!)),
);

/// Packages a [FixtureState] into a [ProjectFileModel] the same way
/// serializeProjectFile does - each map written out as its values list.
ProjectFileModel _toProjectFile(FixtureState state) => ProjectFileModel(
  metadata: const ProjectFileMetadataModel.initial(),
  fixtures: state.fixtures.values.toList(),
  powerMultiOutlets: state.powerMultiOutlets.values.toList(),
  dataMultis: state.dataMultis.values.toList(),
  dataPatches: state.dataPatches.values.toList(),
  locations: state.locations.values.toList(),
  looms: state.looms.values.toList(),
  cables: state.cables.values.toList(),
  maxSequenceBreak: state.maxSequenceBreak,
  balanceTolerance: state.balanceTolerance,
  defaultPowerMulti: state.defaultPowerMulti,
  loomStock: state.loomStock.values.toList(),
  fixtureTypes: state.fixtureTypes.values.toList(),
  hoists: state.hoists.values.toList(),
  hoistControllers: state.hoistControllers.values.toList(),
  hoistMultis: state.hoistMultis.values.toList(),
  powerFeeds: state.powerFeeds.values.toList(),
  powerRacks: state.powerRacks.values.toList(),
  powerRackTypes: state.powerRackTypes.values.toList(),
  dataRacks: state.dataRacks.values.toList(),
  dataRackTypes: state.dataRackTypes.values.toList(),
  fixtureTypePools: state.fixtureTypePools.values.toList(),
  trusses: state.trusses.values.toList(),
  fixtureGeometries: state.fixtureGeometries.values.toList(),
);

/// Builds a coherent [FixtureState] with three locations, each populated with
/// fixtures, power multis, data multis, data patches, hoist multis, hoists and
/// cables. The state is normalized through the same producers the reducer uses
/// so it satisfies the location-order invariant before any reorder is applied.
FixtureState _buildPopulatedState() {
  const locationIds = ['locA', 'locB', 'locC'];
  const prefixes = {'locA': 'A', 'locB': 'B', 'locC': 'C'};

  final locations = <String, LocationModel>{
    for (final id in locationIds)
      id: LocationModel(
        uid: id,
        name: 'Location ${prefixes[id]}',
        color: const LabelColorModel.none(),
        multiPrefix: prefixes[id]!,
        delimiter: '.',
      ),
  };

  final fixtureType = FixtureTypeModel(
    uid: 'wash',
    name: 'Wash',
    shortName: 'Wash',
    amps: 5,
    maxPiggybacks: 1,
  );
  final fixtureTypes = {fixtureType.uid: fixtureType};

  // Three fixtures per location, sequenced 1..3 within each.
  final rawFixtures = <String, FixtureModel>{};
  var fid = 1;
  for (final locationId in locationIds) {
    for (var sequence = 1; sequence <= 3; sequence++) {
      final uid = 'fix-$locationId-$sequence';
      rawFixtures[uid] = FixtureModel(
        uid: uid,
        fid: fid++,
        sequence: sequence,
        typeId: fixtureType.uid,
        locationId: locationId,
      );
    }
  }

  // Power side is the declarative source of truth - run the real patch.
  final patch = performPowerPatch(
    fixtures: rawFixtures,
    fixtureTypes: fixtureTypes,
    powerMultiOutlets: const {},
    locations: locations,
    maxSequenceBreak: 4,
    balanceTolerance: 0.05,
    powerRacks: const {},
    fixtureTypePools: const {},
  );
  final fixtures = FixtureModel.sort(patch.fixtures, locations);
  final powerMultiOutlets = patch.powerMultiOutlets;

  // Hand-build the non-power collections, grouped in location order.
  final rawDataMultis = <String, DataMultiModel>{
    for (final locationId in locationIds)
      'dm-$locationId': DataMultiModel(
        uid: 'dm-$locationId',
        locationId: locationId,
      ),
  };
  final rawHoistMultis = <String, HoistMultiModel>{
    for (final locationId in locationIds)
      'hm-$locationId': HoistMultiModel(
        uid: 'hm-$locationId',
        locationId: locationId,
      ),
  };
  final rawDataPatches = <String, DataPatchModel>{
    for (final (index, locationId) in locationIds.indexed)
      'dp-$locationId': DataPatchModel(
        uid: 'dp-$locationId',
        locationId: locationId,
        universe: index + 1,
      ),
  };
  // Two hoists per location, with user-owned names, to exercise relative
  // ordering preservation.
  final rawHoists = <String, HoistModel>{};
  for (final locationId in locationIds) {
    for (var i = 1; i <= 2; i++) {
      final uid = 'hoist-$locationId-$i';
      rawHoists[uid] = HoistModel(
        uid: uid,
        name: '${prefixes[locationId]} Motor $i',
        locationId: locationId,
        parentController: const HoistControllerChannelAssignment.unassigned(),
        number: i,
        controllerNote: '',
      );
    }
  }

  // A single feeder cable per outlet, plus one spare. Non-multi cable types
  // keep the detached-multi detection dormant so the state stays stable.
  final outletIds = <String>[
    ...powerMultiOutlets.keys,
    ...rawDataMultis.keys,
    ...rawDataPatches.keys,
    ...rawHoistMultis.keys,
    ...rawHoists.keys,
  ];
  final rawCables = <String, CableModel>{
    for (final outletId in outletIds)
      'cable-$outletId': CableModel(
        uid: 'cable-$outletId',
        type: CableType.dmx,
        outletId: outletId,
      ),
    'cable-spare': CableModel(
      uid: 'cable-spare',
      type: CableType.dmx,
      isSpare: true,
    ),
  };

  // Normalize every collection through its real producer so the invariant
  // holds before any reorder.
  final dataMultis = assertMultiOutletState<DataMultiModel>(
    multiOutlets: rawDataMultis,
    locations: locations,
    cables: rawCables,
  );
  final hoistMultis = assertMultiOutletState<HoistMultiModel>(
    multiOutlets: rawHoistMultis,
    locations: locations,
    cables: rawCables,
  );
  final dataPatches = assertDataPatchState(rawDataPatches, locations);
  final cables = assertCableState(
    cables: rawCables,
    powerMultiOutlets: powerMultiOutlets,
    dataMultis: dataMultis,
    dataPatches: dataPatches,
    hoistMultis: hoistMultis,
    hoistOutlets: rawHoists,
  );

  return const FixtureState.initial().copyWith(
    locations: locations,
    fixtureTypes: fixtureTypes,
    fixtures: fixtures,
    powerMultiOutlets: powerMultiOutlets,
    dataMultis: dataMultis,
    hoistMultis: hoistMultis,
    dataPatches: dataPatches,
    hoists: rawHoists,
    cables: cables,
  );
}
