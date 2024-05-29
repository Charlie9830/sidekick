import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class FixtureTypes extends StatelessWidget {
  final FixtureTypesViewModel vm;

  const FixtureTypes({
    Key? key,
    required this.vm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DataTable(
        columns: const [
          // Name
          DataColumn(
            label: Text('Name'),
          ),

          // Qty
          DataColumn(
            label: Text('Qty'),
          ),

          // Max Piggybacks
          DataColumn(label: Text('Max Pairings')),

          // Amps
          DataColumn(label: Text('Amps')),
        ],
        rows: vm.itemVms.map((item) {
          return DataRow(cells: [
            DataCell(
              // Name
              withConstraint(
                PropertyField(
                  value: item.type.name,
                  onBlur: (newValue) =>
                      vm.onNameChanged(item.type.uid, newValue),
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onBlur: (newValue) =>
                    vm.onMaxPairingsChanged(item.type.uid, newValue),
              ),
            )),

            // Amps.
            DataCell(
              Text('${item.type.amps}A'),
            ),
          ]);
        }).toList());
  }

  Widget withConstraint(Widget child, {double? width}) {
    return SizedBox(
      width: width ?? 120,
      child: child,
    );
  }
}
