import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

enum OutletType { powerMulti, dataPatch, dataMulti }

int getNextAvailableDataMultiNumber(
    Iterable<Outlet> existingOutlets, String locationId, OutletType type) {
  return switch (type) {
    OutletType.powerMulti => _nextAvailableOutletNumber<PowerMultiOutletModel>(
        existingOutlets, locationId),
    OutletType.dataPatch =>
      _nextAvailableOutletNumber<DataPatchModel>(existingOutlets, locationId),
    OutletType.dataMulti =>
      _nextAvailableOutletNumber<DataMultiModel>(existingOutlets, locationId),
  };
}

int _nextAvailableOutletNumber<T extends Outlet>(
    Iterable<Outlet> outlets, String locationId) {
  return outlets
          .whereType<T>()
          .where((multi) => multi.locationId == locationId)
          .length +
      1;
}
