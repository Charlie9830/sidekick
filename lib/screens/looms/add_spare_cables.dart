// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/screens/looms/cable_type_select.dart';
import 'package:sidekick/widgets/property_field.dart';

class AddSpareCables extends StatefulWidget {
  final CableType defaultPowerMultiType;
  const AddSpareCables({super.key, required this.defaultPowerMultiType});

  @override
  State<AddSpareCables> createState() => _AddSpareCablesState();
}

class _AddSpareCablesState extends State<AddSpareCables> {
  List<CableRowValue> _valueRows = [];

  @override
  void initState() {
    _valueRows = [CableRowValue(type: widget.defaultPowerMultiType, qty: 1)];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Spare Cable').large,
            const SizedBox(height: 16),
            ..._valueRows
                .mapIndexed((index, row) => FocusTraversalGroup(
                      child: _OptionRow(
                        typeValue: row.type,
                        qty: row.qty,
                        onQtyChanged: (qty) => _handleQtyChanged(index, qty),
                        onTypeChanged: (type) =>
                            _handleTypeChanged(index, type),
                        onClearButtonPressed: index == 0
                            ? null
                            : () => setState(() {
                                  _valueRows = _valueRows.toList()
                                    ..removeAt(index);
                                }),
                      ),
                    ))
                .toList(),
            _Footer(
              onAddRow: () => setState(() => _valueRows.add(
                    _valueRows.first.copyWith(),
                  )),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton.primary(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                trailing: const Text('Create'),
                onPressed: () => _submit(_valueRows),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQtyChanged(int rowIndex, int newQty) {
    final newList = _valueRows.toList();
    final existing = newList[rowIndex];

    newList[rowIndex] = existing.copyWith(qty: newQty);

    setState(() => _valueRows = newList);
  }

  void _handleTypeChanged(int rowIndex, CableType newType) {
    final newList = _valueRows.toList();
    final existing = newList[rowIndex];

    newList[rowIndex] = existing.copyWith(type: newType);

    setState(() => _valueRows = newList);
  }

  void _submit(List<CableRowValue> values) {
    Navigator.of(context).pop(AddSpareCablesResult(values));
  }
}

class _Footer extends StatelessWidget {
  final void Function() onAddRow;

  const _Footer({
    required this.onAddRow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          IconButton.secondary(
              onPressed: onAddRow,
              icon: const Icon(Icons.add_circle),
              trailing: const Text('More')),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final CableType typeValue;
  final int qty;
  final void Function(int newValue) onQtyChanged;
  final void Function(CableType type) onTypeChanged;
  final void Function()? onClearButtonPressed;

  const _OptionRow({
    required this.typeValue,
    required this.qty,
    required this.onQtyChanged,
    required this.onTypeChanged,
    this.onClearButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CableTypeSelect(
          value: typeValue,
          onChanged: (value) => onTypeChanged(value),
        ),
        const SizedBox(width: 24),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SizedBox(
            width: 64,
            child: PropertyField(
              textAlign: TextAlign.center,
              labelAlign: LabelAlign.center,
              value: qty.toString(),
              label: 'Qty',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onBlur: (newValue) {
                onQtyChanged(int.parse(newValue.trim()));
              },
            ),
          ),
        ),
        const SizedBox(width: 24),
        IconButton.destructive(
          icon: const Icon(Icons.remove_circle),
          onPressed: onClearButtonPressed,
        )
      ],
    );
  }
}

class CableRowValue {
  final CableType type;
  final int qty;

  CableRowValue({
    required this.type,
    required this.qty,
  });

  CableRowValue copyWith({
    CableType? type,
    int? qty,
  }) {
    return CableRowValue(
      type: type ?? this.type,
      qty: qty ?? this.qty,
    );
  }
}

class AddSpareCablesResult {
  final List<CableRowValue> values;

  AddSpareCablesResult(this.values);
}
