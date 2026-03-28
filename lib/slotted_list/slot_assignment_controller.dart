import 'dart:math';

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

enum HighlightPolicy {
  allSelected,
  primaryOnly,
}

class SlotAssignmentController<K, V> extends ChangeNotifier {
  Map<K, ItemData<K, V>> itemsById;
  Set<K> selectedAvailableIds = {};
  Set<K> selectedPlacedIds = {};
  final HighlightPolicy highlightPolicy;
  final void Function(Set<K> selectedAvailableIds, Set<K> selectedPlacedIds)?
      onSelectionChanged;
  ValueNotifier<Set<SlotPosition>> highlightedSlots = ValueNotifier({});

  SlotAssignmentController({
    required this.itemsById,
    this.onSelectionChanged,
    this.highlightPolicy = HighlightPolicy.allSelected,
  });

  void setItems(Map<K, ItemData<K, V>> itemsById) {
    this.itemsById = itemsById;
    notifyListeners();
  }

  void setSelectedAvailableIds(Set<K> ids) {
    selectedPlacedIds = {};
    selectedAvailableIds = ids.toSet();

    onSelectionChanged?.call(selectedAvailableIds, selectedPlacedIds);
    notifyListeners();
  }

  void setSelectedPlacedIds(Set<K> ids) {
    selectedPlacedIds = ids.toSet();
    selectedAvailableIds = {};

    onSelectionChanged?.call(selectedAvailableIds, selectedPlacedIds);
    notifyListeners();
  }

  void endDrag() {
    highlightedSlots.value = {};
  }

  void updateDragHover(SlotPosition slotIndex) {
    if (highlightPolicy == HighlightPolicy.primaryOnly) {
      highlightedSlots.value = {slotIndex};
      return;
    }

    final selectedItemCount =
        max(selectedPlacedIds.length, selectedAvailableIds.length);

    final highlightedSlotIndexes = List.generate(
        selectedItemCount,
        (index) => SlotPosition(
              scope: slotIndex.scope,
              index: slotIndex.index + index,
            ));

    highlightedSlots.value = highlightedSlotIndexes.toSet();
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

  static SlotAssignmentController<K, V> of<K, V>(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_SlotAssignmentInherited<K, V>>();

    assert(scope != null, 'No SlotAssignmentScope found in context');

    return scope!.controller;
  }

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
                    child: _SlotAssignmentInherited<K, V>(
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

class _SlotAssignmentInherited<K, V> extends InheritedWidget {
  final SlotAssignmentController<K, V> controller;
  const _SlotAssignmentInherited({
    super.key,
    required super.child,
    required this.controller,
  });

  @override
  bool updateShouldNotify(covariant _SlotAssignmentInherited oldWidget) {
    return oldWidget.controller != controller;
  }
}

typedef ItemBuilder<K, V> = Widget Function(
    BuildContext context, ItemData<K, V>? value, bool selected);

class AvailableItem<K, V> extends StatelessWidget {
  final K id;
  final int selectionIndex;
  final ItemBuilder<K, V> builder;
  final SlotAssignmentController<K, V>? controller;

  const AvailableItem({
    super.key,
    required this.id,
    required this.builder,
    required this.selectionIndex,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final listController = controller ?? SlotAssignmentScope.of<K, V>(context);

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
  final SlotAssignmentController<K, V>? controller;

  const Slot({
    super.key,
    required this.assignedItemId,
    required this.builder,
    required this.slotIndex,
    required this.onItemsLanded,
    this.selectionIndex,
    this.slotIndexScope = '',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final assignmentController =
        controller ?? SlotAssignmentScope.of<K, V>(context);
    return ListenableBuilder(
        listenable: assignmentController,
        builder: (context, _) {
          final item = assignedItemId != null
              ? assignmentController.itemsById[assignedItemId]
              : null;

          final child = builder(context, item,
              assignmentController.selectedPlacedIds.contains(assignedItemId));
          return _wrapActivatedBorder(
            controller: assignmentController,
            slotIndex: slotIndex,
            slotIndexScope: slotIndexScope,
            child: _wrapDragTarget(
              controller: assignmentController,
              child: _wrapSelectionListener(
                item: item,
                selectionIndex: selectionIndex,
                child: _wrapDraggable(
                  child: child,
                  controller: assignmentController,
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
    return ValueListenableBuilder<Set<SlotPosition>>(
      valueListenable: controller.highlightedSlots,
      child: child,
      builder: (context, value, child) => Container(
        foregroundDecoration: controller.highlightedSlots.value
                .contains(scopedSlotIndex)
            ? BoxDecoration(border: Border.all(color: Colors.green, width: 1))
            : null,
        child: child,
      ),
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
