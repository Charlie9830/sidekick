import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/table_view_config.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class _Columns {
  static const int make = 0;
  static const int shortName = 1;
  static const int qty = 2;
  static const int maxPiggybacks = 3;
  static const int fixtureAmps = 4;
  static const int maxAmps = 5;
}

class FixtureTypeDataTable extends StatelessWidget {
  final List<FixtureTypeViewModel> items;

  const FixtureTypeDataTable({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return TableView.builder(
      key: fixtureTypesPageStorageKey,
      pinnedRowCount: 1,
      rowCount: items.length + 1,
      columnBuilder: _columnBuilder,
      rowBuilder: _rowBuilder,
      columnCount: 6,
      cellBuilder: (context, vicinity) =>
          _cellBuilder(context, vicinity, items),
    );
  }

  TableViewCell _buildHeaderCell(BuildContext context, int columnIndex) {
    leftAlign(Widget child) =>
        Align(alignment: Alignment.centerLeft, child: child);

    centerAlign(Widget child) =>
        Align(alignment: Alignment.center, child: child);

    rightAlign(Widget child) =>
        Align(alignment: Alignment.centerRight, child: child);

    return switch (columnIndex) {
      _Columns.make =>
        TableViewCell(child: leftAlign(const Text('Make & Manufacturer'))),
      _Columns.shortName =>
        TableViewCell(child: leftAlign(const Text('Short Name'))),
      _Columns.qty => TableViewCell(child: centerAlign(const Text('Qty'))),
      _Columns.maxPiggybacks =>
        TableViewCell(child: centerAlign(const Text('Max Piggybacks'))),
      _Columns.fixtureAmps =>
        TableViewCell(child: centerAlign(const Text('Amps'))),
      _Columns.maxAmps =>
        TableViewCell(child: centerAlign(const Text('Max Piggybacked Amps'))),
      _ =>
        throw UnimplementedError('No handling for Column Index $columnIndex'),
    };
  }

  TableViewCell _cellBuilder(BuildContext context, TableVicinity vicinity,
      List<FixtureTypeViewModel> fixture) {
    if (vicinity.row == 0) {
      return _buildHeaderCell(context, vicinity.column);
    }

    final item = fixture[vicinity.row - 1];

    final maxPiggybackedLoad =
        (item.type.amps * item.type.maxPiggybacks).toStringAsFixed(1);

    return TableViewCell(
        child: switch (vicinity.column) {
      _Columns.make =>
        Align(alignment: Alignment.centerLeft, child: Text(item.type.name)),
      _Columns.shortName => PropertyField(
          enabled: item.onShortNameChanged != null,
          value: item.type.shortName,
          onBlur: (newValue) => item.onShortNameChanged?.call(newValue),
        ),
      _Columns.qty =>
        Align(alignment: Alignment.center, child: Text(item.qty.toString())),
      _Columns.maxPiggybacks => PropertyField(
          value: item.type.maxPiggybacks.toString(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onBlur: (newValue) => item.onMaxPairingsChanged(newValue),
        ),
      _Columns.fixtureAmps =>
        Align(alignment: Alignment.center, child: Text('${item.type.amps}A')),
      _Columns.maxAmps => Align(
          alignment: Alignment.center,
          child: Text(
              item.type.maxPiggybacks == 1 ? '-' : '${maxPiggybackedLoad}A')),
      _ => throw "Unexpected Vicinity $vicinity",
    });
  }

  TableSpan _rowBuilder(int index) {
    if (index == 0) {
      // Header Row
      return TableViewConfig.defaultHeaderRowSpan;
    }

    // Data Row
    return const TableSpan(extent: FixedSpanExtent(40));
  }

  TableSpan _columnBuilder(int index) {
    const defaultPadding = TableViewConfig.spanPadding;

    return switch (index) {
      _Columns.make => TableSpan(
          extent: const FixedSpanExtent(400),
          padding: defaultPadding,
          foregroundDecoration: TableViewConfig.defaultForegroundDecoration),
      _Columns.shortName => TableSpan(
          extent: const FixedSpanExtent(240),
          padding: defaultPadding,
          foregroundDecoration: TableViewConfig.defaultForegroundDecoration),
      _Columns.qty => TableSpan(
          extent: const FixedSpanExtent(128),
          padding: defaultPadding,
          foregroundDecoration: TableViewConfig.defaultForegroundDecoration),
      _Columns.maxPiggybacks => TableSpan(
          extent: const FixedSpanExtent(128),
          padding: defaultPadding,
          foregroundDecoration: TableViewConfig.defaultForegroundDecoration),
      _Columns.fixtureAmps => TableSpan(
          extent: const FixedSpanExtent(128),
          padding: defaultPadding,
          foregroundDecoration: TableViewConfig.defaultForegroundDecoration),
      _Columns.maxAmps => TableSpan(
          extent: const RemainingSpanExtent(),
          padding: defaultPadding,
          foregroundDecoration:
              TableViewConfig.defaultTrailingForegroundDecoration),
      _ => throw UnimplementedError('No handling for Column Index $index'),
    };
  }
}
