import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/looms_view_model.dart';

class OutletListItem extends StatelessWidget {
  final OutletViewModel vm;
  final bool isSelected;

  const OutletListItem({super.key, required this.vm, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return ShadListItem(
      enabled: !vm.assigned,
      selected: isSelected,
      title: Text(_getTitle(vm), style: Theme.of(context).typography.mono),
      leading: _getLeading(vm),
      trailing:
          Text(_getTrailing(vm), style: Theme.of(context).typography.mono),
    );
  }

  String _getTrailing(OutletViewModel vm) {
    return switch (vm) {
      DataOutletViewModel vm => vm.outlet.universeLabel,
      _ => '',
    };
  }

  Widget _getLeading(OutletViewModel vm) {
    return switch (vm) {
      PowerMultiOutletViewModel _ =>
        const Icon(Icons.bolt, color: SidekickColors.powerRun),
      DataOutletViewModel _ =>
        const Icon(Icons.settings_input_svideo, color: SidekickColors.control),
      HoistOutletViewModel _ =>
        const Icon(Icons.construction, color: SidekickColors.hoist),
      _ => const SizedBox.shrink(),
    };
  }

  String _getTitle(OutletViewModel vm) {
    return switch (vm) {
      PowerMultiOutletViewModel vm => vm.outlet.name,
      DataOutletViewModel vm => vm.outlet.name,
      HoistOutletViewModel vm => vm.outlet.name,
      _ => throw UnimplementedError('Unhandled OutletViewModel type'),
    };
  }
}
