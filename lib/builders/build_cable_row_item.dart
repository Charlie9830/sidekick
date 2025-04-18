import 'package:sidekick/data_selectors/select_show_cable_top_border.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/looms/cable_row_item.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';

CableRowItem buildCableRowItem({
  required CableViewModel vm,
  required int index,
  required Set<String> selectedCableIds,
  required List<LoomItemViewModel> rowVms,
  LoomType? parentLoomType,
  required void Function() requestSelectionFocusCallback,
}) {
  return CableRowItem(
    cable: vm.cable,
    labelColor: vm.labelColor,
    isSelected: selectedCableIds.contains(vm.cable.uid),
    disableLength: vm.cable.parentMultiId.isNotEmpty,
    showTopBorder: selectShowCableTopBorder(index, rowVms),
    dmxUniverse: vm.universe,
    label: vm.label,
    onLengthChanged: (newValue) {
      vm.onLengthChanged(newValue);
      requestSelectionFocusCallback();
    },
    hideLength: vm.cable.parentMultiId.isNotEmpty ||
        parentLoomType == LoomType.permanent,
  );
}
