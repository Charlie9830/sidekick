import 'package:sidekick/redux/models/cable_model.dart';

bool selectCanRemoveSelectedCablesFromLoom(List<CableModel> selectedCables) {
  return selectedCables
      .every((cable) => cable.loomId.isNotEmpty && cable.isSpare == false);
}
