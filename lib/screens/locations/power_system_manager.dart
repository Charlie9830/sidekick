import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/power_system_model.dart';
import 'package:sidekick/utils/get_uid.dart';

class PowerSystemManager extends StatefulWidget {
  final List<PowerSystemModel> existingSystems;
  const PowerSystemManager({super.key, this.existingSystems = const []});

  @override
  State<PowerSystemManager> createState() => _PowerSystemManagerState();
}

class _PowerSystemManagerState extends State<PowerSystemManager> {
  late Map<String, PowerSystemModel> _systems;
  late Map<String, FocusNode> _textFocusNodes;

  @override
  void initState() {
    _systems = widget.existingSystems.toModelMap();
    _textFocusNodes = _systems
        .map((id, system) => MapEntry(id, FocusNode(canRequestFocus: true)));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final systems = _systems.values.toList();
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Power Systems').textLarge,
            const SizedBox(height: 16),
            ListView.builder(
                shrinkWrap: true,
                itemCount: systems.length,
                itemBuilder: (context, index) {
                  final item = systems[index];
                  return _SystemItem(
                      key: Key(item.uid),
                      focusNode: _textFocusNodes[item.uid]!,
                      name: item.name,
                      isDefault: item.isDefault,
                      onChanged: (newValue) => setState(() => _systems =
                          Map<String, PowerSystemModel>.from(_systems)
                            ..update(
                                item.uid,
                                (existing) =>
                                    existing.copyWith(name: newValue.trim()))),
                      onDelete: () => _handleSystemItemDelete(item));
                }),
            IconButton.secondary(
              icon: const Icon(Icons.add),
              onPressed: _handleNewSystemButtonPressed,
            ),
            const Spacer(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8.0,
              children: [
                Button.destructive(
                  child: Text('Cancel'),
                ),
                Button.primary(child: Text('Apply')),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleSystemItemDelete(PowerSystemModel item) {
    if (item.isDefault) {
      return;
    }

    setState(() {
      _systems = Map<String, PowerSystemModel>.from(_systems)..remove(item.uid);
      _textFocusNodes.remove(item.uid)?.dispose();
    });
  }

  void _handleNewSystemButtonPressed() {
    setState(() {
      final newSystem = PowerSystemModel(uid: getUid(), name: 'New System');

      _systems = Map<String, PowerSystemModel>.from(_systems)
        ..addAll({newSystem.uid: newSystem});

      _textFocusNodes.putIfAbsent(
          newSystem.uid, () => FocusNode(canRequestFocus: true));

      _textFocusNodes[newSystem.uid]!.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final node in _textFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}

class _SystemItem extends StatelessWidget {
  final String name;
  final bool isDefault;
  final FocusNode focusNode;
  final void Function(String newValue) onChanged;
  final void Function() onDelete;
  const _SystemItem({
    super.key,
    required this.name,
    required this.focusNode,
    required this.onDelete,
    this.isDefault = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: focusNode,
              initialValue: name,
              onSubmitted: (newValue) => onChanged(newValue),
              hintText: 'System name',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: switch (isDefault) {
              true => Chip(child: const Text('Default').textMuted),
              false => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton.outline(
                        icon: const Icon(Icons.delete),
                        onPressed: () => onDelete()).iconSmall,
                  ],
                )
            },
          )
        ],
      ),
    );
  }
}
