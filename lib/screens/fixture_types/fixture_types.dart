import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/fixture_types/fixture_type_data_table.dart';
import 'package:sidekick/screens/fixture_types/fixture_type_pools.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class FixtureTypes extends StatelessWidget {
  final FixtureTypesViewModel vm;

  const FixtureTypes({
    Key? key,
    required this.vm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        NavigationBar(
          selectedKey: ValueKey(vm.tabIndex),
          onSelected: (key) => vm.onTabChanged((key as ValueKey<int>).value),
          alignment: NavigationBarAlignment.start,
          expanded: false,
          children: const [
            NavigationItem(
              key: ValueKey(0),
              child: Text('Fixture Types'),
            ),
            NavigationItem(
              key: ValueKey(1),
              child: Text('Pools'),
            )
          ],
        ),
        Toolbar(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Checkbox(
              state: vm.showAllFixtureTypes
                  ? CheckboxState.checked
                  : CheckboxState.unchecked,
              onChanged: (newValue) => vm.onShowAllFixtureTypesChanged(
                  newValue == CheckboxState.checked ? true : false),
            ),
            const SizedBox(width: 8),
            const Text('Show All'),
          ],
        )),
        Expanded(
            child: switch (vm.tabIndex) {
          0 => FixtureTypeDataTable(
              items: vm.fixtureTypeVms,
            ),
          _ => FixtureTypePools(viewModel: vm)
        }),
      ],
    );
  }
}
