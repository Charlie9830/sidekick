import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';

bool selectCableDetachedState(
    {required Map<String, DataMultiModel> dataMultis,
    required CableModel cable}) {
  final associatedOutlet = dataMultis[cable.outletId];

  return associatedOutlet?.isDetached ?? false;
}
