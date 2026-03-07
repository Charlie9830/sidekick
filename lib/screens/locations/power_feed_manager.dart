import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/extension_methods/clone_map.dart';
import 'package:sidekick/redux/models/power_feed_model.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/utils/get_uid.dart';
import 'package:sidekick/widgets/property_field.dart';

class PowerFeedManagerResult {
  final Map<String, PowerFeedModel> powerFeeds;
  final Set<String> deletedFeedIds;

  PowerFeedManagerResult({
    required this.powerFeeds,
    required this.deletedFeedIds,
  });
}

class PowerFeedManager extends StatefulWidget {
  final Map<String, PowerFeedModel> existingPowerFeeds;
  const PowerFeedManager({
    super.key,
    this.existingPowerFeeds = const {},
  });

  @override
  State<PowerFeedManager> createState() => _PowerFeedManagerState();
}

class _PowerFeedManagerState extends State<PowerFeedManager> {
  late Map<String, PowerFeedModel> _feeds;
  Set<String> _deletedFeedIds = {};

  @override
  void initState() {
    _feeds = widget.existingPowerFeeds.clone();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final feeds = _feeds.values.toList();
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Power Feeds').textLarge,
                SimpleTooltip(
                  message: 'Add Feed',
                  child: IconButton.secondary(
                    icon: const Icon(Icons.add),
                    onPressed: _handleAddFeedButtonPressed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                  itemCount: feeds.length,
                  itemBuilder: (context, index) {
                    final item = feeds[index];
                    return _FeedItem(
                      isDefault: item.uid == PowerFeedModel.kDefaultPowerFeedId,
                      onDelete: () {
                        if (item.uid == PowerFeedModel.kDefaultPowerFeedId) {
                          return;
                        }

                        final updatedFeeds = _feeds.clone()..remove(item.uid);
                        final deletedFeedIds = {..._deletedFeedIds, item.uid};

                        setState(() {
                          _feeds = updatedFeeds;
                          _deletedFeedIds = deletedFeedIds;
                        });
                      },
                      name: item.name,
                      capacity: item.capacity,
                      onCapacityChanged: (newValue) => setState(() {
                        _feeds = _feeds.clone()
                          ..update(
                              item.uid,
                              (existing) => existing.copyWith(
                                  capacity: int.tryParse(newValue.trim())));
                      }),
                      onNameChanged: (newValue) => setState(() {
                        _feeds = _feeds.clone()
                          ..update(
                              item.uid,
                              (existing) =>
                                  existing.copyWith(name: newValue.trim()));
                      }),
                    );
                  }),
            ),
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
                        Navigator.of(context).pop(PowerFeedManagerResult(
                          powerFeeds: _feeds,
                          deletedFeedIds: _deletedFeedIds,
                        )),
                    child: const Text('Apply')),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleAddFeedButtonPressed() {
    setState(() {
      final newFeed = PowerFeedModel(
          uid: getUid(),
          name: 'Feed ${_feeds.values.length + 1}',
          capacity: 400);

      _feeds = _feeds.clone()..addAll({newFeed.uid: newFeed});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _FeedItem extends StatelessWidget {
  final String name;
  final int capacity;
  final bool isDefault;
  final void Function(String newValue) onNameChanged;
  final void Function(String newValue) onCapacityChanged;
  final void Function() onDelete;

  const _FeedItem({
    required this.name,
    required this.capacity,
    required this.isDefault,
    required this.onNameChanged,
    required this.onCapacityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isDefault)
            const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Chip(
                child: Text('Default'),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              SimpleTooltip(
                message: isDefault ? 'Cannot remove default feed' : null,
                child: IconButton.ghost(
                  icon: const Icon(Icons.clear),
                  size: ButtonSize.small,
                  onPressed: isDefault ? null : onDelete,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
