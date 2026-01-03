import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/view_models/racks_view_model.dart';

class PowerRack extends StatelessWidget {
  final PowerRackItem vm;
  const PowerRack({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
          child: Column(
        children: [
          Row(
            children: [
              Text(vm.rack.name),
            ],
          ),
          Text(vm.rack.notes, style: Theme.of(context).typography.light),
          _OutletTable(outlets: vm.children),
        ],
      )),
    );
  }
}

class _OutletTable extends StatelessWidget {
  final List<PowerOutletItem> outlets;

  const _OutletTable({
    super.key,
    required this.outlets,
  });

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(color: Theme.of(context).colorScheme.border);
    return Table(
      defaultRowHeight: const FixedTableSize(28),
      columnWidths: const {0: FixedTableSize(64), 1: FixedTableSize(124)},
      rows: outlets.mapIndexed((index, outlet) {
        final bottomBorderSide = index == outlets.length - 1
            ? const BorderSide(color: Colors.transparent)
            : borderSide;

        return TableRow(
          cellTheme: const TableCellTheme(
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          ),
          cells: [
            TableCell(
                backgroundColor: Colors.transparent,
                theme: TableCellTheme(
                    border: WidgetStatePropertyAll(Border(
                  bottom: bottomBorderSide,
                  right: borderSide,
                ))),
                child: Center(
                  child: Text((outlet.index + 1).toString(),
                      style: Theme.of(context).typography.mono),
                )),
            TableCell(
                backgroundColor: Colors.transparent,
                theme: TableCellTheme(
                    border: WidgetStatePropertyAll(Border(
                  bottom: bottomBorderSide,
                  right: borderSide,
                ))),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(outlet.outletName,
                        style: Theme.of(context).typography.mono),
                  ),
                )),
            TableCell(
                backgroundColor: Colors.transparent,
                theme: TableCellTheme(
                    border: WidgetStatePropertyAll(Border(
                  bottom: bottomBorderSide,
                ))),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(outlet.locationName,
                          style: Theme.of(context).typography.light),
                    ))),
          ],
        );
      }).toList(),
    );
  }
}
