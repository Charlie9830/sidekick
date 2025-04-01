import 'package:flutter/material.dart';
import 'package:sidekick/view_models/looms_v2_view_model.dart';

class OutletListTile extends StatelessWidget {
  final OutletViewModel vm;
  final bool isSelected;

  const OutletListTile({super.key, required this.vm, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        enabled: !vm.assigned,
        selected: isSelected,
        title: Text(_getTitle(vm)),
        leading: _getLeading(vm),
        trailing: Text(_getTrailing(vm)),
        selectedTileColor: Theme.of(context).focusColor.withAlpha(60),
        selectedColor: Theme.of(context).textTheme.labelLarge!.color);
  }

  String _getTrailing(OutletViewModel vm) {
    return switch (vm) {
      DataOutletViewModel vm => vm.outlet.universeLabel,
      _ => '',
    };
  }

  Widget _getLeading(OutletViewModel vm) {
    return switch (vm) {
      PowerMultiOutletViewModel vm =>
        const Icon(Icons.bolt, color: Colors.yellowAccent),
      DataOutletViewModel vm => const Icon(Icons.settings_input_svideo),
      _ => const SizedBox.shrink(),
    };
  }

  String _getTitle(OutletViewModel vm) {
    return switch (vm) {
      PowerMultiOutletViewModel vm => vm.outlet.name,
      DataOutletViewModel vm => vm.outlet.name,
      _ => throw UnimplementedError('Unhandled OutletViewModel type'),
    };
  }
}
