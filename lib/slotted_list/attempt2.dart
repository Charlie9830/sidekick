import 'dart:math';

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

class SlotAssignmentController<K, V> extends ChangeNotifier {
  Map<K, ItemData<K, V>> itemsById;
  Set<K> selectedAvailableIds = {};
  Set<K> selectedPlacedIds = {};
  final void Function(Set<K> selectedAvailableIds, Set<K> selectedPlacedIds)?
      onSelectionChanged;
  Set<SlotPosition> highlightedSlots = {};

  SlotAssignmentController({
    required this.itemsById,
    this.onSelectionChanged,
  });

  void setItems(Map<K, ItemData<K, V>> itemsById) {
    this.itemsById = itemsById;
    notifyListeners();
  }

  void endDrag() {
    highlightedSlots = {};
    notifyListeners();
  }

  void updateDragHover(SlotPosition slotIndex) {
    final selectedItemCount =
        max(selectedPlacedIds.length, selectedAvailableIds.length);

    final highlightedSlotIndexes = List.generate(
        selectedItemCount,
        (index) => SlotPosition(
              scope: slotIndex.scope,
              index: slotIndex.index + index,
            ));

    highlightedSlots = highlightedSlotIndexes.toSet();
    notifyListeners();
  }

  void updateAvailableSelection(
      UpdateType type, Set<AvailableItemIdWrapper<K>> wrappedIds) {
    final unwrappedIds = wrappedIds.map((wrapper) => wrapper.id).toSet();
    final updatedIds = switch (type) {
      UpdateType.overwrite => unwrappedIds.toSet(),
      UpdateType.addIfAbsentElseRemove => selectedAvailableIds.toSet()
        ..addAllIfAbsentElseRemove(unwrappedIds)
    };

    selectedPlacedIds = {};
    selectedAvailableIds = {...updatedIds};
    onSelectionChanged?.call(selectedAvailableIds, selectedPlacedIds);
    notifyListeners();
  }

  void updatePlacedSelection(
      UpdateType type, Set<PlacedItemIdWrapper<K>> wrappedItemIds) {
    final unwrappedIds = wrappedItemIds.map((wrapper) => wrapper.id).toSet();
    final updatedIds = switch (type) {
      UpdateType.overwrite => unwrappedIds.toSet(),
      UpdateType.addIfAbsentElseRemove => selectedPlacedIds.toSet()
        ..addAllIfAbsentElseRemove(unwrappedIds)
    };
    selectedPlacedIds = {...updatedIds};
    selectedAvailableIds = {};
    onSelectionChanged?.call(selectedAvailableIds, selectedPlacedIds);
    notifyListeners();
  }
}

class SlotAssignmentScope<K, V> extends StatefulWidget {
  final SlotAssignmentController<K, V> controller;
  final Widget child;

  const SlotAssignmentScope({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<SlotAssignmentScope<K, V>> createState() =>
      _SlotAssignmentScopeState<K, V>();
}

class _SlotAssignmentScopeState<K, V> extends State<SlotAssignmentScope<K, V>> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.controller,
        child: widget.child,
        builder: (context, child) {
          return _wrapDragController(
            child: _wrapCandidateItemSelectionContainer(
                child: _wrapAssignedItemSelectionContainer(
                    child: SlotAssignmentScope2<K, V>(
              controller: widget.controller,
              child: child!,
            ))),
          );
        });
  }

  Widget _wrapDragController({required Widget child}) {
    return DragProxyController(child: child);
  }

  Widget _wrapCandidateItemSelectionContainer({required Widget child}) {
    return ItemSelectionContainer<AvailableItemIdWrapper<K>>(
      selectedItemIds: widget.controller.selectedAvailableIds
          .map((id) => AvailableItemIdWrapper<K>(id))
          .toSet(),
      onSelectionUpdated: widget.controller.updateAvailableSelection,
      child: child,
    );
  }

  Widget _wrapAssignedItemSelectionContainer({required Widget child}) {
    return ItemSelectionContainer<PlacedItemIdWrapper<K>>(
      debug: true,
      selectedItemIds: widget.controller.selectedPlacedIds
          .map((id) => PlacedItemIdWrapper<K>(id))
          .toSet(),
      onSelectionUpdated: widget.controller.updatePlacedSelection,
      child: child,
    );
  }
}

class SlotAssignmentScope2<K, V> extends InheritedWidget {
  final SlotAssignmentController<K, V> controller;
  const SlotAssignmentScope2({
    super.key,
    required super.child,
    required this.controller,
  });

  static SlotAssignmentScope2<K, V>? maybeOf<K, V>(BuildContext context) {
    if (context.mounted == false) {
      return null;
    }

    return context
        .dependOnInheritedWidgetOfExactType<SlotAssignmentScope2<K, V>>();
  }

  @override
  bool updateShouldNotify(covariant SlotAssignmentScope2 oldWidget) {
    return oldWidget.controller != controller;
  }
}

typedef ItemBuilder<K, V> = Widget Function(
    BuildContext context, ItemData<K, V>? value, bool selected);

class AvailableItem<K, V> extends StatelessWidget {
  final K id;
  final int selectionIndex;
  final ItemBuilder<K, V> builder;
  final SlotAssignmentController<K, V>? fallbackController;

  const AvailableItem({
    super.key,
    required this.id,
    required this.builder,
    required this.selectionIndex,
    this.fallbackController,
  });

  @override
  Widget build(BuildContext context) {
    final listController =
        SlotAssignmentScope2.maybeOf<K, V>(context)?.controller ??
            fallbackController!;

    return ListenableBuilder(
        listenable: listController,
        builder: (context, _) {
          final item = listController.itemsById[id];

          final child = builder(
              context, item, listController.selectedAvailableIds.contains(id));
          return _wrapSelectionListener(
            item: item,
            selectionIndex: selectionIndex,
            context: context,
            child: _wrapDraggable(
                context: context,
                child: child,
                controller: listController,
                item: item),
          );
        });
  }

  Widget _wrapDraggable(
      {required Widget child,
      required BuildContext context,
      required SlotAssignmentController<K, V>? controller,
      required ItemData<K, V>? item}) {
    if (controller == null ||
        item == null ||
        DragProxyMessenger.of(context) == null) {
      return child;
    }

    return LongPressDraggableProxy<ItemDragData<K>>(
      feedback: SizedBox(width: 400, child: child),
      onDragCompleted: () => controller.endDrag(),
      onDragEnd: (details) => controller.endDrag(),
      onDraggableCanceled: (vel, details) => controller.endDrag(),
      data: ItemDragData(itemIds: controller.selectedAvailableIds.toList()),
      child: child,
    );
  }

  Widget _wrapSelectionListener({
    required Widget child,
    required ItemData? item,
    required int selectionIndex,
    required BuildContext context,
  }) {
    if (item == null ||
        ItemSelectionMessenger.maybeOf<AvailableItemIdWrapper<K>>(context) ==
            null) {
      return child;
    }

    return ItemSelectionListener<AvailableItemIdWrapper<K>>(
      itemId: AvailableItemIdWrapper<K>(item.id),
      index: selectionIndex,
      child: child,
    );
  }
}

typedef SlotBuilder<K, V> = Widget Function(
    BuildContext context, ItemData<K, V>? value, bool selected);

class Slot<K, V> extends StatelessWidget {
  final K? assignedItemId;
  final String slotIndexScope;
  final int slotIndex;
  final int? selectionIndex;
  final ItemBuilder<K, V> builder;
  final void Function(List<K> itemIds) onItemsLanded;

  const Slot({
    super.key,
    required this.assignedItemId,
    required this.builder,
    required this.slotIndex,
    required this.onItemsLanded,
    this.selectionIndex,
    this.slotIndexScope = '',
  });

  @override
  Widget build(BuildContext context) {
    final controller = SlotAssignmentScope2.maybeOf<K, V>(context)!.controller;
    return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final item = assignedItemId != null
              ? controller.itemsById[assignedItemId]
              : null;

          final child = builder(context, item,
              controller.selectedPlacedIds.contains(assignedItemId));
          return _wrapActivatedBorder(
            controller: controller,
            slotIndex: slotIndex,
            slotIndexScope: slotIndexScope,
            child: _wrapDragTarget(
              controller: controller,
              child: _wrapSelectionListener(
                item: item,
                selectionIndex: selectionIndex,
                child: _wrapDraggable(
                  child: child,
                  controller: controller,
                  item: item,
                ),
              ),
            ),
          );
        });
  }

  Widget _wrapActivatedBorder(
      {required Widget child,
      required SlotAssignmentController<K, V>? controller,
      required String slotIndexScope,
      required int slotIndex}) {
    if (controller == null) {
      return child;
    }

    final scopedSlotIndex =
        SlotPosition(scope: slotIndexScope, index: slotIndex);
    return Container(
      foregroundDecoration:
          controller.highlightedSlots.contains(scopedSlotIndex)
              ? BoxDecoration(border: Border.all(color: Colors.green, width: 1))
              : null,
      child: child,
    );
  }

  Widget _wrapDragTarget(
      {required Widget child,
      required SlotAssignmentController<K, V>? controller}) {
    return DragTargetProxy<ItemDragData<K>>(
      onAcceptWithDetails: (details) {
        onItemsLanded(details.data.itemIds);
      },
      onWillAcceptWithDetails: (details) {
        controller?.updateDragHover(
            SlotPosition(scope: slotIndexScope, index: slotIndex));

        return true;
      },
      builder: (context, candidateItems, rejectedItems) {
        return child;
      },
    );
  }

  Widget _wrapDraggable(
      {required Widget child,
      required SlotAssignmentController<K, V>? controller,
      required ItemData<K, V>? item}) {
    if (controller == null || item == null) {
      return child;
    }

    return LongPressDraggableProxy<ItemDragData<K>>(
      feedback: SizedBox(width: 1200, child: child),
      onDragCompleted: () => controller.endDrag(),
      onDragEnd: (details) => controller.endDrag(),
      onDraggableCanceled: (vel, details) => controller.endDrag(),
      data: ItemDragData<K>(itemIds: controller.selectedPlacedIds.toList()),
      child: child,
    );
  }

  Widget _wrapSelectionListener(
      {required Widget child,
      required ItemData? item,
      required int? selectionIndex}) {
    if (item == null || selectionIndex == null) {
      return child;
    }

    return ItemSelectionListener<PlacedItemIdWrapper<K>>(
      itemId: PlacedItemIdWrapper<K>(item.id),
      index: selectionIndex,
      child: child,
    );
  }
}

class SlotPosition {
  final String scope;
  final int index;

  SlotPosition({
    required this.scope,
    required this.index,
  });

  @override
  bool operator ==(Object other) {
    return other is SlotPosition &&
        other.scope == scope &&
        other.index == index;
  }

  @override
  int get hashCode => scope.hashCode ^ index.hashCode;
}

class ItemData<K, V> {
  final K id;
  final V item;

  ItemData({
    required this.id,
    required this.item,
  });
}

class AvailableItemIdWrapper<K> {
  final K id;

  AvailableItemIdWrapper(this.id);

  @override
  bool operator ==(Object other) {
    return other is AvailableItemIdWrapper && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return id.toString();
  }
}

class PlacedItemIdWrapper<K> {
  final K id;

  PlacedItemIdWrapper(this.id);

  @override
  bool operator ==(Object other) {
    return other is PlacedItemIdWrapper && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return id.toString();
  }
}

class ItemDragData<K> {
  final List<K> itemIds;

  ItemDragData({
    required this.itemIds,
  });
}
