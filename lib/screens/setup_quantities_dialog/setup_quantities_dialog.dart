import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';

class SetupQuantitiesDialog extends StatefulWidget {
  final List<LoomStockModel> items;
  const SetupQuantitiesDialog({super.key, required this.items});

  @override
  State<SetupQuantitiesDialog> createState() => _SetupQuantitiesDialogState();
}

class _SetupQuantitiesDialogState extends State<SetupQuantitiesDialog> {
  late Map<String, LoomStockModel> _items;

  @override
  void initState() {
    _items = widget.items.toModelMap();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items.values.toList();

    return SizedBox(
      child: AlertDialog(
        title: const Text('Setup Permanent Loom Quantities'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_items),
            child: const Text('Done'),
          ),
        ],
        content: SizedBox(
          height: 600,
          width: 500,
          child: Column(
            children: [
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return ListTile(
                      title: Text(item.fullName),
                      trailing: SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: EditableTextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                value: item.qty.toString(),
                                onChanged: (newValue) => setState(() =>
                                    _items = _items.clone()
                                      ..update(
                                          item.uid,
                                          (existing) => existing.copyWith(
                                              qty:
                                                  int.parse(newValue.trim())))),
                                selectAllOnFocus: true,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Text('In Stock',
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }
}
