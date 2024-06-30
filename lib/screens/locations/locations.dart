import 'package:flutter/material.dart';
import 'package:sidekick/screens/locations/color_chit.dart';
import 'package:sidekick/screens/locations/color_select_dialog.dart';
import 'package:sidekick/view_models/locations_view_model.dart';
import 'package:sidekick/widgets/icon_label.dart';
import 'package:sidekick/widgets/property_field.dart';

class Locations extends StatelessWidget {
  final LocationsViewModel vm;
  const Locations({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Colours')),
            DataColumn(label: Text('Loom Prefix')),
            DataColumn(
                label: IconLabel(
              icon: Icon(Icons.electric_bolt, color: Colors.yellow),
              label: 'Multi qty',
            )),
            DataColumn(
                label: IconLabel(
              icon: Icon(Icons.settings_input_svideo, color: Colors.blue),
              label: 'Multi (Patch) qty',
            )),
          ],
          rows: vm.itemVms.map((item) {
            withConstraint(Widget child, {double? width}) =>
                SizedBox(width: width ?? 120, child: child);

            return DataRow(key: ValueKey(item.location.uid), cells: [
              // Name
              DataCell(
                withConstraint(
                  PropertyField(
                    value: item.location.name,
                    onBlur: (newValue) =>
                        vm.onLocationNameChanged(item.location.uid, newValue),
                  ),
                  width: 240,
                ),
              ),

              // Colours
              DataCell(SizedBox(
                height: 48,
                width: 48,
                child: InkWell(
                  onTap: () => _showColorPickerDialog(
                      context, item.location.uid, item.location.color),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ColorChit(
                      color: item.location.color,
                    ),
                  ),
                ),
              )),

              DataCell(
                withConstraint(
                  PropertyField(
                    value: item.location.multiPrefix,
                    onBlur: (newValue) =>
                        vm.onMultiPrefixChanged(item.location.uid, newValue),
                  ),
                ),
              ),

              // Multi Qty
              DataCell(Text(item.powerMultiCount.toString())),

              // Data Multi
              DataCell(Text('${item.dataMultiCount} (${item.dataPatchCount})'))
            ]);
          }).toList()),
    );
  }

  void _showColorPickerDialog(
      BuildContext context, String id, Color color) async {
    final result = await showDialog(
        context: context, builder: (_) => ColorSelectDialog(color: color));

    if (result == null) {
      return;
    }

    if (result is Color) {
      vm.onLocationColorChanged(id, result);
    }
  }
}
