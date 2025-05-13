import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

class DataPatchViewModel {
  final List<DataPatchRow> rows;
  final bool honorDataSpans;
  final void Function(bool newValue) onHonorDataSpansChanged;

  DataPatchViewModel({
    required this.rows,
    required this.onHonorDataSpansChanged,
    required this.honorDataSpans,
  });
}

abstract class DataPatchRow {}

class LocationRow extends DataPatchRow {
  final LocationModel location;

  LocationRow(this.location);
}

class SingleDataPatchRow extends DataPatchRow {
  final DataPatchModel patch;

  SingleDataPatchRow(this.patch);
}
