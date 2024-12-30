import 'package:sidekick/view_models/loom_item_view_model.dart';

bool selectShowCableTopBorder(int index, List<LoomItemViewModel> rowVms) {
  if (rowVms.isEmpty || rowVms.length == 1) {
    return true;
  }

  return index == 0 || rowVms[index - 1] is! CableViewModel;
}
