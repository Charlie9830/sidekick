import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class AddSpareCables extends StatefulWidget {
  const AddSpareCables({super.key});

  @override
  State<AddSpareCables> createState() => _AddSpareCablesState();
}

class _AddSpareCablesState extends State<AddSpareCables> {
  CableType _selectedType = CableType.socapex;
  int _qty = 1;

  final _qtyFocusNode = FocusNode();
  final _mainFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _mainFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyUpEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _submit(_selectedType, _qty);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: SizedBox(
          height: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 128,
                    child: DropdownButton<CableType>(
                        isExpanded: true,
                        value: _selectedType,
                        onChanged: (type) => setState(() {
                              _selectedType = type ?? _selectedType;
                              _qtyFocusNode.requestFocus();
                            }),
                        items: const [
                          DropdownMenuItem(
                              value: CableType.socapex, child: Text('Socapex')),
                          DropdownMenuItem(
                              value: CableType.wieland6way,
                              child: Text('6way')),
                          DropdownMenuItem(
                              value: CableType.sneak, child: Text('Sneak')),
                          DropdownMenuItem(
                              value: CableType.dmx, child: Text('DMX')),
                        ]),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: 100,
                      child: PropertyField(
                        focusNode: _qtyFocusNode,
                        value: _qty.toString(),
                        label: 'Qty',
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onBlur: (newValue) {
                          setState(() {
                            _qty = int.tryParse(newValue.trim()) ?? 1;
                          });

                          _mainFocusNode.requestFocus();
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _submit(_selectedType, _qty),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(CableType type, int qty) {
    Navigator.of(context).pop(AddSpareCablesResult(type, qty));
  }

  @override
  void dispose() {
    _mainFocusNode.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }
}

class AddSpareCablesResult {
  final CableType type;
  final int qty;

  AddSpareCablesResult(this.type, this.qty);
}
