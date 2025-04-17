import 'package:sidekick/data_selectors/select_show_cable_top_border.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/looms/cable_row_item.dart';
import 'package:sidekick/view_models/cable_view_model.dart';
import 'package:sidekick/view_models/loom_view_model.dart';

CableRowItem buildCableRowItem({
  required CableViewModel vm,
  required int index,
  required Set<String> selectedCableIds,
  required List<LoomViewModel> rowVms,
  LoomType? parentLoomType,
  required void Function() requestSelectionFocusCallback,
  required bool missingUpstreamCable,
}) {
  return CableRowItem(
    cable: vm.cable,
    localNumber: vm.localNumber,
    labelColor: vm.labelColor,
    isSelected: selectedCableIds.contains(vm.cable.uid),
    disableLength: vm.cable.parentMultiId.isNotEmpty ||
        parentLoomType == LoomType.permanent,
    showTopBorder: selectShowCableTopBorder(index, rowVms),
    dmxUniverse: vm.universe,
    label: vm.label,
    onLengthChanged: (newValue) {
      vm.onLengthChanged(newValue);
      requestSelectionFocusCallback();
    },
    missingUpstreamCable: missingUpstreamCable,
  );
}
