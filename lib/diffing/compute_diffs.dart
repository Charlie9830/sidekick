import 'package:collection/collection.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:sidekick/view_models/cable_qty_diffing_item_view_model.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/fixture_diffing_item_view_model.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';
import 'package:sidekick/view_models/hoist_controller_diffing_view_model.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';
import 'package:sidekick/view_models/loom_diffing_item_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';
import 'package:sidekick/view_models/patch_diffing_item_view_model.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';

/// Classifies every id present in [current] or [original] as
/// [DiffState.added], [DiffState.deleted], or [DiffState.unchanged], then maps
/// each pairing to a result via [build].
///
/// This is the shared skeleton behind every `compute*Diffs` function: an id is
/// *added* when it exists only in [current], *deleted* when it exists only in
/// [original], and *unchanged* when it exists in both. Callers turn the result
/// into a list with `.toList()` or a keyed map with `.toModelMap()`.
Iterable<T> diffById<M, T>({
  required Map<String, M> current,
  required Map<String, M> original,
  required T Function(String id, M? current, M? original, DiffState state) build,
}) {
  final allIds = {...current.keys, ...original.keys};

  return allIds.map((id) {
    final currentValue = current[id];
    final originalValue = original[id];
    final state = switch ((currentValue, originalValue)) {
      (_, null) => DiffState.added,
      (null, _) => DiffState.deleted,
      _ => DiffState.unchanged,
    };

    return build(id, currentValue, originalValue, state);
  });
}

List<CableQtyDiffingItemViewModel> computeCableQtyDiffs({
  required Map<String, Map<CableQtyGroup, int>> currentQtys,
  required Map<String, Map<CableQtyGroup, int>> originalQtys,
  required Map<String, String> currentLocationNames,
  required Map<String, String> originalLocationNames,
}) {
  final allLocationIds = {...currentQtys.keys, ...originalQtys.keys};

  return allLocationIds.map((locationId) {
    final current = currentQtys[locationId] ?? const {};
    final original = originalQtys[locationId] ?? const {};

    final overallDiff = switch ((current.isEmpty, original.isEmpty)) {
      (false, true) => DiffState.added,
      (true, false) => DiffState.deleted,
      _ => DiffState.unchanged,
    };

    final allGroups = {...current.keys, ...original.keys};
    final deltas = allGroups
        .map(
          (group) => CableQtyDelta(
            group: group,
            currentQty: current[group] ?? 0,
            originalQty: original[group] ?? 0,
          ),
        )
        .toList();

    return CableQtyDiffingItemViewModel(
      locationId: locationId,
      locationName:
          currentLocationNames[locationId] ??
          originalLocationNames[locationId] ??
          '',
      overallDiff: overallDiff,
      deltas: deltas,
    );
  }).toList();
}

List<FixtureDiffingItemViewModel> computeFixtureDiffs({
  required Map<String, FixtureTableRowViewModel> currentFixtureVms,
  required Map<String, FixtureTableRowViewModel> originalFixtureVms,
}) {
  return diffById(
    current: currentFixtureVms,
    original: originalFixtureVms,
    build: (id, current, original, state) => FixtureDiffingItemViewModel(
      current: current,
      original: original,
      overallDiff: state,
      deltas: state == DiffState.unchanged
          ? current!.calculateDeltas(original!)
          : const PropertyDeltaSet.empty(),
    ),
  ).toList();
}

List<PatchDiffingItemViewModel> computePatchDiffs({
  required Map<String, PowerPatchRowViewModel> currentPatchVms,
  required Map<String, PowerPatchRowViewModel> originalPatchVms,
}) {
  return diffById(
    current: currentPatchVms,
    original: originalPatchVms,
    build: (id, current, original, state) => PatchDiffingItemViewModel(
      current: current,
      original: original,
      overallDiff: state,
      deltas: state == DiffState.unchanged
          ? current!.calculateDeltas(original!)
          : const PropertyDeltaSet.empty(),
      outletDeltas: state == DiffState.unchanged
          ? computeOutletDeltas(original: original!, current: current!)
          : const [],
    ),
  ).toList();
}

List<LoomDiffingItemViewModel> computeLoomDiffs({
  required Map<String, LoomViewModel> currentLoomVms,
  required Map<String, LoomViewModel> originalLoomVms,
}) {
  return diffById(
    current: currentLoomVms,
    original: originalLoomVms,
    build: (id, current, original, state) => LoomDiffingItemViewModel(
      current: current,
      original: original,
      overallDiff: state,
      deltas: state == DiffState.unchanged
          ? current!.calculateDeltas(original!)
          : const PropertyDeltaSet.empty(),
      cableDeltas: computeCableDeltas(
        original?.children.toModelMap() ?? {},
        current?.children.toModelMap() ?? {},
      ),
    ),
  ).toList();
}

List<HoistControllerDiffingViewModel> computeHoistControllerDiffs({
  required Map<String, HoistControllerViewModel> currentControllerVms,
  required Map<String, HoistControllerViewModel> originalControllerVms,
  required Map<String, HoistViewModel> currentHoistVms,
  required Map<String, HoistViewModel> originalHoistVms,
}) {
  final hoistDeltas = computeHoistDeltas(
    originalHoists: originalHoistVms,
    currentHoists: currentHoistVms,
  );

  return diffById(
    current: currentControllerVms,
    original: originalControllerVms,
    build: (id, current, original, state) => HoistControllerDiffingViewModel(
      current: current,
      original: original,
      overallDiff: state,
      deltas: state == DiffState.unchanged
          ? current!.calculateDeltas(original!)
          : const PropertyDeltaSet.empty(),
      channelDeltas: computeHoistChannelDeltas(
        originalChannels: original?.channels.toModelMap() ?? {},
        currentChannels: current?.channels.toModelMap() ?? {},
        hoistDeltas: hoistDeltas,
      ),
    ),
  ).toList();
}

List<OutletDelta> computeOutletDeltas({
  required PowerPatchRowViewModel original,
  required PowerPatchRowViewModel current,
}) {
  if (original is! MultiOutletRowViewModel ||
      current is! MultiOutletRowViewModel) {
    return [];
  }

  return current.childOutlets.mapIndexed((index, currentChild) {
    final originalChild = original.childOutlets[index];

    return OutletDelta(
      multiPatchIndex: index,
      properties: currentChild.calculateDeltas(originalChild),
    );
  }).toList();
}

Map<String, HoistDelta> computeHoistDeltas({
  required Map<String, HoistViewModel> originalHoists,
  required Map<String, HoistViewModel> currentHoists,
}) {
  return diffById(
    current: currentHoists,
    original: originalHoists,
    build: (id, current, original, state) => HoistDelta(
      uid: id,
      overallDiff: state,
      properties: state == DiffState.unchanged
          ? original!.calculateDeltas(current!)
          : const PropertyDeltaSet.empty(),
    ),
  ).toModelMap();
}

Map<String, HoistChannelDelta> computeHoistChannelDeltas({
  required Map<String, HoistChannelViewModel> originalChannels,
  required Map<String, HoistChannelViewModel> currentChannels,
  required Map<String, HoistDelta> hoistDeltas,
}) {
  const emptyHoistDelta = HoistDelta(
    uid: '',
    overallDiff: DiffState.unchanged,
    properties: PropertyDeltaSet.empty(),
  );

  return diffById(
    current: currentChannels,
    original: originalChannels,
    build: (id, current, original, state) {
      if (state == DiffState.deleted) {
        return HoistChannelDelta(
          uid: id,
          overallDiff: DiffState.deleted,
          channelProperties: const PropertyDeltaSet.empty(),
          hoistDelta: const HoistDelta(
            uid: '',
            overallDiff: DiffState.deleted,
            properties: PropertyDeltaSet.empty(),
          ),
        );
      }

      if (state == DiffState.added) {
        final hoistId = current!.hoist?.uid ?? '';
        return HoistChannelDelta(
          uid: id,
          overallDiff: DiffState.added,
          channelProperties: const PropertyDeltaSet.empty(),
          hoistDelta: hoistDeltas[hoistId] ?? emptyHoistDelta,
        );
      }

      return HoistChannelDelta(
        uid: id,
        overallDiff: DiffState.unchanged,
        channelProperties: current!.calculateDeltas(original!),
        hoistDelta: hoistDeltas[current.hoist?.uid] ?? emptyHoistDelta,
      );
    },
  ).toModelMap();
}

Map<String, CableDelta> computeCableDeltas(
  Map<String, CableViewModel> original,
  Map<String, CableViewModel> current,
) {
  return diffById(
    current: current,
    original: original,
    build: (id, currentCable, originalCable, state) => CableDelta(
      uid: id,
      overallDiff: state,
      properties: state == DiffState.unchanged
          ? currentCable!.calculateDeltas(originalCable!)
          : const PropertyDeltaSet.empty(),
    ),
  ).toModelMap();
}

class CableDelta implements ModelCollectionMember {
  @override
  final String uid;
  final DiffState overallDiff;
  final PropertyDeltaSet properties;

  CableDelta({
    required this.uid,
    required this.overallDiff,
    required this.properties,
  });
}

class OutletDelta {
  final int multiPatchIndex;
  final PropertyDeltaSet properties;

  OutletDelta({required this.multiPatchIndex, required this.properties});
}

class HoistChannelDelta implements ModelCollectionMember {
  @override
  final String uid;
  final DiffState overallDiff;
  final PropertyDeltaSet channelProperties;
  final HoistDelta hoistDelta;

  HoistChannelDelta({
    required this.uid,
    required this.overallDiff,
    required this.channelProperties,
    required this.hoistDelta,
  });
}

class HoistDelta implements ModelCollectionMember {
  @override
  final String uid;
  final DiffState overallDiff;
  final PropertyDeltaSet properties;

  const HoistDelta({
    required this.uid,
    required this.overallDiff,
    required this.properties,
  });
}

class PowerMultiChannelDelta implements ModelCollectionMember {
  @override
  final String uid;
  final DiffState overallDiff;
  final PropertyDeltaSet channelProperties;
  final PowerMultiOutletDelta multiDelta;

  PowerMultiChannelDelta({
    required this.uid,
    required this.overallDiff,
    required this.channelProperties,
    required this.multiDelta,
  });
}

class PowerMultiOutletDelta implements ModelCollectionMember {
  @override
  final String uid;
  final DiffState overallDiff;
  final PropertyDeltaSet properties;

  PowerMultiOutletDelta({
    required this.uid,
    required this.overallDiff,
    required this.properties,
  });
}
