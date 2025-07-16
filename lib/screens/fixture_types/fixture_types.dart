import 'package:flutter/material.dart';
import 'package:sidekick/screens/fixture_types/fixture_type_data_table.dart';
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
        Toolbar(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Checkbox(
              value: vm.showAllFixtureTypes,
              onChanged: (newValue) =>
                  vm.onShowAllFixtureTypesChanged(newValue ?? false),
            ),
            const SizedBox(width: 8),
            const Text('Show All'),
          ],
        )),
        Expanded(
          child: SingleChildScrollView(
            child: FixtureTypeDataTable(
              items: vm.itemVms,
            ),
          ),
        ),
      ],
    );
  }
}
