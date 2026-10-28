import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/fixture_types/fixture_type_data_table.dart';
import 'package:sidekick/screens/fixture_types/fixture_type_geometry_view.dart';
import 'package:sidekick/screens/fixture_types/fixture_type_pools.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class FixtureTypes extends StatelessWidget {
  final FixtureTypesViewModel vm;

  const FixtureTypes({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Toolbar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                state: vm.showAllFixtureTypes
                    ? CheckboxState.checked
                    : CheckboxState.unchecked,
                onChanged: (newValue) => vm.onShowAllFixtureTypesChanged(
                  newValue == CheckboxState.checked ? true : false,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Show All'),
              const Spacer(),
              NavigationBar(
                backgroundColor: Colors.transparent,
                selectedKey: ValueKey(vm.tabIndex),
                onSelected: (key) =>
                    vm.onTabChanged((key as ValueKey<int>).value),
                alignment: NavigationBarAlignment.start,
                expanded: false,
                children: const [
                  NavigationItem(
                    key: ValueKey(0),
                    child: Text('Fixture Types'),
                  ),
                  NavigationItem(key: ValueKey(1), child: Text('Pools')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (vm.tabIndex) {
            0 => _FixtureTypesTab(vm: vm),
            _ => FixtureTypePools(viewModel: vm),
          },
        ),
      ],
    );
  }
}

/// Width of the 3D preview panel beside the fixture type table.
const double _kPreviewPanelWidth = 420;

/// The fixture type table, with a 3D preview of the selected type beside it.
class _FixtureTypesTab extends StatelessWidget {
  final FixtureTypesViewModel vm;

  const _FixtureTypesTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final selected = vm.fixtureTypeVms.firstWhereOrNull(
      (type) => type.uid == vm.selectedFixtureTypeId,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FixtureTypeDataTable(
            items: vm.fixtureTypeVms,
            selectedId: selected?.uid,
            onSelected: vm.onFixtureTypeSelected,
          ),
        ),
        if (selected != null) ...[
          const VerticalDivider(),
          SizedBox(
            width: _kPreviewPanelWidth,
            child: FixtureTypeGeometryView(
              vm: selected,
              onClose: () => vm.onFixtureTypeSelected(null),
            ),
          ),
        ],
      ],
    );
  }
}
