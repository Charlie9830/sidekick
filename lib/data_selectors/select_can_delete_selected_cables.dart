import 'package:sidekick/redux/models/cable_model.dart';

bool selectCanDeleteSelectedCables(List<CableModel> selectedCables) {
  return selectedCables
      .any((cable) => cable.upstreamId.isNotEmpty || cable.isSpare);
}
