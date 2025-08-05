import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/hoist_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

List<T> assertOutletNameAndNumbers<T extends Outlet>(
    Iterable<Outlet> outlets, Map<String, LocationModel> locations) {
  final typedOutlets = outlets.whereType<T>();

  final outletsByLocationId =
      typedOutlets.groupListsBy((outlet) => outlet.locationId);

  return outletsByLocationId.entries
      .map((entry) {
        final locationId = entry.key;

        final location = locations[locationId]!;
        final outletsInLocation = entry.value;

        return outletsInLocation.mapIndexed((index, outlet) =>
            _updateOutletNameAndNumber(outlet,
                location.getPrefixedNameByType(outlet, index + 1), index + 1));
      })
      .flattened
      .toList()
      .cast<T>();
}

Outlet _updateOutletNameAndNumber(Outlet outlet, String name, int number) {
  return switch (outlet) {
    PowerMultiOutletModel o => o.copyWith(name: name, number: number),
    DataPatchModel o => o.copyWith(name: name, number: number),
    DataMultiModel o => o.copyWith(name: name, number: number),
    HoistModel o => o.copyWith(name: name, number: number),
    HoistMultiModel o => o.copyWith(name: name, number: number),
    _ => throw UnimplementedError('No handling for Type ${outlet.runtimeType}')
  };
}
