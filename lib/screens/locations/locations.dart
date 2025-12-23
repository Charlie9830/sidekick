import 'package:flutter/material.dart';
import 'package:sidekick/page_storage_keys.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/locations/color_select_dialog.dart';

import 'package:sidekick/screens/locations/multi_color_chit.dart';
import 'package:sidekick/screens/locations/power_system_manager.dart';

import 'package:sidekick/view_models/locations_view_model.dart';

import 'package:sidekick/widgets/property_field.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

class _Columns {
  static const int name = 0;
  static const int color = 1;
  static const int prefix = 2;
  static const int delimiter = 3;
  static const int hoists = 4;
  static const int powerMultis = 5;
  static const int data = 6;
  static const int powerSystem = 7;
  static const int actions = 8;
}

const String _kNewPowerSystemValue = "new-power-system";

class Locations extends StatefulWidget {
  final LocationsViewModel vm;
  const Locations({Key? key, required this.vm}) : super(key: key);

  @override
  State<Locations> createState() => _LocationsState();
}

class _LocationsState extends State<Locations> {
  late final ScrollableDetails _scrollableDetails;

  @override
  void initState() {
    _scrollableDetails = ScrollableDetails.horizontal(
        controller: ScrollController(
            keepScrollOffset:
                false)); // Stops PageStorageKey triggering weird animations on Page navigation.
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TableView.builder(
        key: locationsPageStorageKey,
        horizontalDetails: _scrollableDetails,
        pinnedRowCount: 1,
        columnCount: 9,
        rowCount: widget.vm.itemVms.length + 1,
        columnBuilder: _columnBuilder,
        rowBuilder: (index) => _rowBuilder(context, index),
        cellBuilder: _cellBuilder);
  }

  TableViewCell _cellBuilder(BuildContext context, TableVicinity vicinity) {
    if (vicinity.row == 0) {
      return _buildHeaderCell(context, vicinity.column);
    }

    final item = widget.vm.itemVms[vicinity.row - 1];

    return TableViewCell(
        child: switch (vicinity.column) {
      _Columns.name =>
        Align(alignment: Alignment.centerLeft, child: Text(item.location.name)),
      _Columns.color => InkWell(
          onTap: () => _showColorPickerDialog(
              context, item.location.uid, item.location.color),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: MultiColorChit(
                height: 18,
                value: item.location.color,
              ),
            ),
          ),
        ),
      _Columns.prefix => PropertyField(
          value: item.location.multiPrefix,
          onBlur: (newValue) =>
              widget.vm.onMultiPrefixChanged(item.location.uid, newValue),
        ),
      _Columns.delimiter => PropertyField(
          value: item.location.delimiter,
          onBlur: (newValue) =>
              widget.vm.onLocationDelimiterChanged(item.location.uid, newValue),
        ),
      _Columns.hoists => Align(
          alignment: Alignment.center, child: Text(item.motorCount.toString())),
      _Columns.powerMultis => Align(
          alignment: Alignment.center,
          child: Text(item.powerMultiCount.toString())),
      _Columns.data => Align(
          alignment: Alignment.center,
          child: Text('${item.dataMultiCount} (${item.dataPatchCount})')),
      _Columns.powerSystem => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: shad.Select<String>(
              canUnselect: false,
              itemBuilder: (context, item) => Text(item),
              onChanged: (value) =>
                  _handlePowerSystemValueChanged(context, value),
              value: 'System A',
              popup: shad.SelectPopup<String>(
                  items: shad.SelectItemList(children: [
                ...widget.vm.powerSystemVms
                    .map((systemItem) => shad.SelectItemButton(
                          value: systemItem.system.uid,
                          child: Text(systemItem.system.name),
                        )),
                const Divider(),
                const shad.SelectItemButton(
                    value: _kNewPowerSystemValue, child: Text('Manage...'))
              ]))),
        ),
      _Columns.actions => Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<String>(
              enabled: item.location.isRiggingOnlyLocation,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: item.location.isRiggingOnlyLocation,
                      onTap: () => item.onEditName(),
                      child: const Text('Edit name'),
                    ),
                    PopupMenuItem(
                      enabled: item.location.isRiggingOnlyLocation,
                      onTap: () => item.onDelete(),
                      child: const Text('Delete'),
                    )
                  ]),
        ),
      _ => throw "Unexpected Vicinity $vicinity",
    });
  }

  void _handlePowerSystemValueChanged(
      BuildContext context, String? value) async {
    if (value == null) {
      return;
    }

    if (value == _kNewPowerSystemValue) {
      await shad.openSheet(
          context: context,
          builder: (context) => PowerSystemManager(
              existingSystems:
                  widget.vm.powerSystemVms.map((vm) => vm.system).toList()),
          position: shad.OverlayPosition.right);
      return;
    }
  }

  TableViewCell _buildHeaderCell(BuildContext context, int columnIndex) {
    leftAlign(Widget child) =>
        Align(alignment: Alignment.centerLeft, child: child);

    centerAlign(Widget child) =>
        Align(alignment: Alignment.center, child: child);

    rightAlign(Widget child) =>
        Align(alignment: Alignment.centerRight, child: child);

    return switch (columnIndex) {
      _Columns.name => TableViewCell(child: leftAlign(const Text('Name'))),
      _Columns.color => TableViewCell(child: leftAlign(const Text('Color'))),
      _Columns.prefix => TableViewCell(child: leftAlign(const Text('Prefix'))),
      _Columns.delimiter =>
        TableViewCell(child: leftAlign(const Text('Delimiter'))),
      _Columns.hoists => TableViewCell(
          child: centerAlign(
            const _IconTitle(
              icon: Icon(Icons.construction),
              title: 'Hoist Quantity',
            ),
          ),
        ),
      _Columns.powerMultis => TableViewCell(
          child: centerAlign(
            const _IconTitle(
              icon: Icon(Icons.electric_bolt, color: Colors.yellow),
              title: 'Power Multi Quantity',
            ),
          ),
        ),
      _Columns.data => TableViewCell(
          child: centerAlign(
            const _IconTitle(
              icon: Icon(Icons.settings_input_svideo, color: Colors.blue),
              title: 'Data Multi Quantity (Patch Quantity)',
            ),
          ),
        ),
      _Columns.powerSystem =>
        TableViewCell(child: leftAlign(const Text('Power System'))),
      _Columns.actions =>
        TableViewCell(child: rightAlign(const Text('Actions'))),
      _ => throw "Unexpected Column Index $columnIndex",
    };
  }

  TableSpan _columnBuilder(int index) {
    final minorBorder = BorderSide(color: Colors.grey.shade800);
    const defaultPadding = SpanPadding(leading: 8.0, trailing: 8.0);

    return switch (index) {
      _Columns.name => const TableSpan(
          extent: FixedSpanExtent(240),
          padding: defaultPadding,
        ),
      _Columns.color => const TableSpan(
          extent: FixedSpanExtent(120),
          padding: defaultPadding,
        ),
      _Columns.prefix => const TableSpan(
          extent: FixedSpanExtent(190),
          padding: defaultPadding,
        ),
      _Columns.delimiter => const TableSpan(
          extent: FixedSpanExtent(190),
          padding: defaultPadding,
        ),
      _Columns.hoists => TableSpan(
          extent: const FixedSpanExtent(64),
          foregroundDecoration:
              SpanDecoration(border: SpanBorder(leading: minorBorder)),
          padding: defaultPadding,
        ),
      _Columns.powerMultis => TableSpan(
          extent: const FixedSpanExtent(64),
          foregroundDecoration:
              SpanDecoration(border: SpanBorder(leading: minorBorder)),
          padding: defaultPadding,
        ),
      _Columns.data => TableSpan(
          extent: const FixedSpanExtent(64),
          foregroundDecoration: SpanDecoration(
              border: SpanBorder(leading: minorBorder, trailing: minorBorder)),
          padding: defaultPadding,
        ),
      _Columns.powerSystem => const TableSpan(
          extent: FixedSpanExtent(180),
          padding: defaultPadding,
        ),
      _Columns.actions => const TableSpan(
          extent: FixedSpanExtent(120),
          padding: defaultPadding,
        ),
      _ => throw "Unexpect column Index $index",
    };
  }

  TableSpan _rowBuilder(BuildContext context, int index) {
    if (index == 0) {
      // Header Row
      return TableSpan(
        extent: const FixedSpanExtent(56),
        backgroundDecoration: SpanDecoration(
          color: Theme.of(context).cardColor,
          border: SpanBorder(
            trailing: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
      );
    }

    // Data Row
    return const TableSpan(extent: FixedSpanExtent(56));
  }

  void _showColorPickerDialog(
      BuildContext context, String id, LabelColorModel color) async {
    final result = await showDialog(
        context: context, builder: (_) => ColorSelectDialog(color: color));

    if (result == null) {
      return;
    }

    if (result is LabelColorModel) {
      widget.vm.onLocationColorChanged(id, result);
    }
  }
}

class _IconTitle extends StatelessWidget {
  final Icon icon;
  final String title;
  const _IconTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title,
      child: icon,
    );
  }
}
