import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';
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
            child: DataTable(
                columns: const [
                  // Name
                  DataColumn(
                    tooltip:
                        'Taken from the Make and Manufacturer columns of the Fixture Database.',
                    label: Text('Original Make & Model'),
                  ),

                  // Original Short Name
                  DataColumn(
                      tooltip:
                          'Taken from the Short Name (Patchinator, IJAP) column of the Fixture Database.',
                      label: Text('Original Short Name')),

                  // Short Name
                  DataColumn(
                    label: Text('Short Name'),
                  ),

                  // Qty
                  DataColumn(
                    label: Text('Qty'),
                  ),

                  // Max Piggybacks
                  DataColumn(label: Text('Max Piggybacks')),

                  // Amps
                  DataColumn(label: Text('Amps')),
                ],
                rows: vm.itemVms.map((item) {
                  final piggybackedLoadSuffix = item.type.maxPiggybacks > 1
                      ? '    (${(item.type.amps * item.type.maxPiggybacks).toStringAsFixed(1)}A)'
                      : '';
                  return DataRow(cells: [
                    DataCell(
                      // Original Make & Model
                      Text(item.type.name),
                    ),

                    // Original Short Name
                    DataCell(
                      Text(item.type.originalShortName),
                    ),

                    // Short Name
                    DataCell(
                      // Name
                      withConstraint(
                        PropertyField(
                          value: item.type.shortName,
                          onBlur: (newValue) =>
                              vm.onShortNameChanged(item.type.uid, newValue),
                        ),
                        width: 240,
                      ),
                    ),

                    // Qty
                    DataCell(
                      Text(item.qty.toString()),
                    ),

                    // Max Piggybacks.
                    DataCell(withConstraint(
                      PropertyField(
                        value: item.type.maxPiggybacks.toString(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onBlur: (newValue) =>
                            vm.onMaxPairingsChanged(item.type.uid, newValue),
                      ),
                    )),

                    // Amps.
                    DataCell(
                      Text('${item.type.amps}A$piggybackedLoadSuffix'),
                    ),
                  ]);
                }).toList()),
          ),
        ),
      ],
    );
  }

  Widget withConstraint(Widget child, {double? width}) {
    return SizedBox(
      width: width ?? 120,
      child: child,
    );
  }
}
