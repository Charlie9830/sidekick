import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/loom_type_model.dart';
import 'package:sidekick/screens/looms/power_multi_selector.dart';
import 'package:sidekick/view_models/looms_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class LoomsToolbar extends StatelessWidget {
  final LoomsViewModel vm;
  final void Function() requestSelectionFocusCallback;

  const LoomsToolbar({
    super.key,
    required this.vm,
    required this.requestSelectionFocusCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Toolbar(
      child: Row(
        children: [
          ElevatedButton.icon(
              onPressed: vm.onGenerateLoomsButtonPressed,
              icon: const Icon(Icons.cable),
              label: const Text('Generate')),
          OutlinedButton.icon(
            onPressed: () =>
                vm.onCombineCablesIntoNewLoomButtonPressed(LoomType.permanent),
            icon: const Icon(Icons.add),
            label: const Text('Permanent'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () =>
                vm.onCombineCablesIntoNewLoomButtonPressed(LoomType.custom),
            icon: const Icon(Icons.add),
            label: const Text('Custom'),
          ),
          const VerticalDivider(),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Extension'),
            onPressed: vm.onCreateExtensionFromSelection,
          ),
          const VerticalDivider(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Cable',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.grey)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Remove from Loom',
                    child: IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: vm.onRemoveSelectedCablesFromLoom,
                    ),
                  ),
                  Tooltip(
                    message: 'Delete',
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: vm.onDeleteSelectedCables,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              )
            ],
          ),
          const VerticalDivider(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Sneak',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.grey)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Combine',
                    child: IconButton(
                      icon: const Icon(Icons.merge),
                      onPressed: vm.onCombineDmxIntoSneak,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Split',
                    child: IconButton(
                      icon: const Icon(Icons.call_split),
                      onPressed: vm.onSplitSneakIntoDmx,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(width: 16),
          PowerMultiSelector(
            onChanged: (type) {
              requestSelectionFocusCallback();
              vm.onDefaultPowerMultiChanged(type);
            },
            value: vm.defaultPowerMulti,
            onChangedExistingPressed: vm.onChangeExistingPowerMultiTypes,
          )
        ],
      ),
    );
  }
}
