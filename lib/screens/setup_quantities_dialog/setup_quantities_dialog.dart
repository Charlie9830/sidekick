import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/permanent_loom_composition.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/utils/get_uid.dart';

class SetupQuantitiesDialog extends StatefulWidget {
  final List<LoomStockItemViewModelBase> items;
  const SetupQuantitiesDialog({super.key, required this.items});

  @override
  State<SetupQuantitiesDialog> createState() => _SetupQuantitiesDialogState();
}

class _SetupQuantitiesDialogState extends State<SetupQuantitiesDialog> {
  late Map<String, LoomStockItemViewModelBase> _items;

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
          Button.primary(
            onPressed: () => Navigator.of(context).pop(_items.values
                .whereType<LoomStockItemViewModel>()
                .map((vm) => vm.item)
                .toModelMap()),
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
                    final itemVm = items[index];

                    return switch (itemVm) {
                      LoomStockItemViewModel v => ShadListItem(
                          title: Text(v.item.fullName),
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
                                    value: v.item.qty.toString(),
                                    onChanged: (newValue) => setState(() =>
                                        _items = _items.clone()
                                          ..update(
                                              v.uid,
                                              (existing) => (existing
                                                          as LoomStockItemViewModel)
                                                      .copyWith(
                                                          item: v.item.copyWith(
                                                    qty: int.parse(
                                                      newValue.trim(),
                                                    ),
                                                  )))),
                                    selectAllOnFocus: true,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Text('In Stock',
                                    style: Theme.of(context).typography.small),
                              ],
                            ),
                          ),
                        ),
                      LoomStockItemDividerViewModel() =>
                        const Divider(endIndent: 108),
                      _ => const SizedBox(),
                    };
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

abstract class LoomStockItemViewModelBase implements ModelCollectionMember {}

class LoomStockItemViewModel extends LoomStockItemViewModelBase {
  final LoomStockModel item;
  final PermanentLoomComposition parentComposition;

  @override
  String get uid => item.uid;

  LoomStockItemViewModel({
    required this.item,
    required this.parentComposition,
  });

  LoomStockItemViewModel copyWith({LoomStockModel? item}) {
    return LoomStockItemViewModel(
      item: item ?? this.item,
      parentComposition: parentComposition,
    );
  }
}

class LoomStockItemDividerViewModel extends LoomStockItemViewModelBase {
  @override
  String uid = getUid();

  LoomStockItemDividerViewModel();
}
