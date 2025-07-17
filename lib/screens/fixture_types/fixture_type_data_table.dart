import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class FixtureTypeDataTable extends StatelessWidget {
  final List<FixtureTypeViewModel> items;

  const FixtureTypeDataTable({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
        columns: const [
          // Name
          DataColumn(
            tooltip:
                'Taken from the Make and Manufacturer columns of the Fixture Database.',
            label: Text('Make and Manufacturer'),
          ),

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
        rows: items.map((item) {
          final piggybackedLoadSuffix = item.type.maxPiggybacks > 1
              ? '    (${(item.type.amps * item.type.maxPiggybacks).toStringAsFixed(1)}A)'
              : '';
          return DataRow(cells: [
            DataCell(
              // Original Make & Model
              Text(item.type.name),
            ),

            // Short Name
            DataCell(
              // Name
              _withConstraint(
                PropertyField(
                  enabled: item.onShortNameChanged != null,
                  value: item.type.shortName,
                  onBlur: (newValue) => item.onShortNameChanged?.call(newValue),
                ),
                width: 240,
              ),
            ),

            // Qty
            DataCell(
              Text(item.qty.toString()),
            ),

            // Max Piggybacks.
            DataCell(_withConstraint(
              Row(
                children: [
                  Expanded(
                    child: PropertyField(
                      value: item.type.maxPiggybacks.toString(),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onBlur: (newValue) => item.onMaxPairingsChanged(newValue),
                    ),
                  ),
                  if (item.onMaxPairingsOverrideUnset != null)
                    Tooltip(
                      message: 'Reset override',
                      child: IconButton(
                        icon: Icon(Icons.clear,
                            size: 16,
                            color: Theme.of(context).colorScheme.tertiary),
                        onPressed: () =>
                            item.onMaxPairingsOverrideUnset!.call(),
                      ),
                    )
                ],
              ),
            )),

            // Amps.
            DataCell(
              Text('${item.type.amps}A$piggybackedLoadSuffix'),
            ),
          ]);
        }).toList());
  }

  Widget _withConstraint(Widget child, {double? width}) {
    return SizedBox(
      width: width ?? 120,
      child: child,
    );
  }
}
