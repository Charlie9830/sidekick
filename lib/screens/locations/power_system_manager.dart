import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/redux/models/power_system_model.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:sidekick/widgets/property_field.dart';

class PowerSystemManagerResult {
  final Map<String, PowerSystemModel> systems;
  final Map<String, PowerFeedModel> powerFeeds;

  PowerSystemManagerResult({
    required this.systems,
    required this.powerFeeds,
  });
}

class PowerSystemManager extends StatefulWidget {
  final List<PowerSystemModel> existingSystems;
  final Map<String, PowerFeedModel> existingPowerFeeds;
  const PowerSystemManager({
    super.key,
    this.existingSystems = const [],
    this.existingPowerFeeds = const {},
  });

  @override
  State<PowerSystemManager> createState() => _PowerSystemManagerState();
}

class _PowerSystemManagerState extends State<PowerSystemManager> {
  late Map<String, PowerSystemModel> _systems;
  late Map<String, PowerFeedModel> _feeds;

  @override
  void initState() {
    _systems = widget.existingSystems.toModelMap();
    _feeds = widget.existingPowerFeeds.clone();
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
                    name: item.name,
                    isDefault: item.isDefault,
                    childFeeds: _feeds.values
                        .where((feed) => feed.powerSystemId == item.uid)
                        .toList(),
                    onNameChanged: (newValue) => setState(() {
                      _systems = _systems.clone()
                        ..update(
                            item.uid,
                            (existing) =>
                                existing.copyWith(name: newValue.trim()));
                    }),
                    onDelete: () => _handleSystemItemDelete(item),
                    onAddFeed: () => setState(() {
                      final newFeed = PowerFeedModel(
                          uid: getUid(),
                          powerSystemId: item.uid,
                          name:
                              'Feed ${_feeds.values.where((i) => i.powerSystemId == item.uid).length + 1} ',
                          capacity: 400);
                      _feeds = _feeds.clone()
                        ..addAll({
                          newFeed.uid: newFeed,
                        });
                    }),
                    onDeleteFeed: (id) => setState(() {
                      _feeds = _feeds.clone()..remove(id);
                    }),
                    onFeedCapacityChanged: (feedId, newValue) => setState(() {
                      _feeds = _feeds.clone()
                        ..update(
                            feedId,
                            (existing) => existing.copyWith(
                                capacity: int.tryParse(newValue)));
                    }),
                    onFeedNameChanged: (feedId, newValue) => setState(() {
                      _feeds = _feeds.clone()
                        ..update(
                            feedId,
                            (existing) =>
                                existing.copyWith(name: newValue.trim()));
                    }),
                  );
                }),
            IconButton.secondary(
              icon: const Icon(Icons.add),
              onPressed: _handleNewSystemButtonPressed,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8.0,
              children: [
                Button.destructive(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                Button.primary(
                    onPressed: () =>
                        Navigator.of(context).pop(PowerSystemManagerResult(
                          powerFeeds: _feeds,
                          systems: _systems,
                        )),
                    child: const Text('Apply')),
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
    });
  }

  void _handleNewSystemButtonPressed() {
    setState(() {
      final newSystem = PowerSystemModel(uid: getUid(), name: 'New System');

      _systems = Map<String, PowerSystemModel>.from(_systems)
        ..addAll({newSystem.uid: newSystem});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _SystemItem extends StatelessWidget {
  final String name;
  final bool isDefault;
  final List<PowerFeedModel> childFeeds;
  final void Function(String newValue) onNameChanged;
  final void Function() onDelete;
  final void Function() onAddFeed;
  final void Function(String id) onDeleteFeed;
  final void Function(String id, String newValue) onFeedNameChanged;
  final void Function(String id, String newValue) onFeedCapacityChanged;

  const _SystemItem({
    super.key,
    required this.name,
    required this.onDelete,
    required this.childFeeds,
    this.isDefault = true,
    required this.onNameChanged,
    required this.onAddFeed,
    required this.onDeleteFeed,
    required this.onFeedNameChanged,
    required this.onFeedCapacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 8.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PropertyField(
                      value: name,
                      onBlur: (newValue) => onNameChanged(newValue),
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
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...childFeeds.map((feed) => _FeedItem(
                          capacity: feed.capacity,
                          name: feed.name,
                          onCapacityChanged: (newValue) =>
                              onFeedCapacityChanged(feed.uid, newValue),
                          onNameChanged: (newValue) =>
                              onFeedNameChanged(feed.uid, newValue),
                          onDelete: () => onDeleteFeed(feed.uid),
                        )),
                    const SizedBox(height: 8.0),
                    SimpleTooltip(
                      message: 'Add Power Feed',
                      child: IconButton.secondary(
                        icon: const Icon(Icons.add_circle),
                        size: ButtonSize.small,
                        onPressed: onAddFeed,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  final String name;
  final int capacity;
  final void Function(String newValue) onNameChanged;
  final void Function(String newValue) onCapacityChanged;
  final void Function() onDelete;

  const _FeedItem({
    required this.name,
    required this.capacity,
    required this.onNameChanged,
    required this.onCapacityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.subdirectory_arrow_right, color: Colors.gray),
          ),
          Expanded(
            flex: 3,
            child: PropertyField(
                value: name, label: 'Name', onBlur: onNameChanged),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            flex: 2,
            child: PropertyField(
              value: capacity.toString(),
              label: 'Capacity',
              suffix: 'Amps',
              onBlur: onCapacityChanged,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton.destructive(
            icon: const Icon(Icons.clear),
            size: ButtonSize.small,
            onPressed: onDelete,
          )
        ],
      ),
    );
  }
}
