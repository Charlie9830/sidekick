import 'dart:math';

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';
import 'package:sidekick/item_selection/item_selection_messenger.dart';

class AssignableItemListController<K, V> extends ChangeNotifier {
  Map<K, AssignableItem<K, V>> items;
  Set<K> selectedCandidateItemIds = {};
  Set<K> selectedAssignedItemIds = {};
  final void Function(Set<K> selectedCandidateIds, Set<K> selectedAssignedIds)?
      onSelectionChanged;
  Set<ScopedSlotIndex> activatedSlotIndexes = {};

  AssignableItemListController({
    required this.items,
    this.onSelectionChanged,
  });

  void updateItems(Map<K, AssignableItem<K, V>> items) {
    this.items = items;
    notifyListeners();
  }

  void handleDragEnded() {
    activatedSlotIndexes = {};
    notifyListeners();
  }

  void handleDragOver(ScopedSlotIndex slotIndex) {
    final selectedItemCount =
        max(selectedAssignedItemIds.length, selectedCandidateItemIds.length);

    final activatedSlotIndexes = List.generate(
        selectedItemCount,
        (index) => ScopedSlotIndex(
              scope: slotIndex.scope,
              index: slotIndex.index + index,
            ));

    this.activatedSlotIndexes = activatedSlotIndexes.toSet();
    notifyListeners();
  }

  void handleCandidateSelectionUpdated(
      UpdateType type, Set<CandidateItemIdWrapper<K>> wrappedIds) {
    final unwrappedIds = wrappedIds.map((wrapper) => wrapper.id).toSet();
    final updatedIds = switch (type) {
      UpdateType.overwrite => unwrappedIds.toSet(),
      UpdateType.addIfAbsentElseRemove => selectedCandidateItemIds.toSet()
        ..addAllIfAbsentElseRemove(unwrappedIds)
    };

    selectedAssignedItemIds = {};
    selectedCandidateItemIds = {...updatedIds};
    onSelectionChanged?.call(selectedCandidateItemIds, selectedAssignedItemIds);
    notifyListeners();

    print("Updated");
  }

  void handleAssignedItemSelectionUpdated(
      UpdateType type, Set<AssignedItemIdWrapper<K>> wrappedItemIds) {
    final unwrappedIds = wrappedItemIds.map((wrapper) => wrapper.id).toSet();
    final updatedIds = switch (type) {
      UpdateType.overwrite => unwrappedIds.toSet(),
      UpdateType.addIfAbsentElseRemove => selectedAssignedItemIds.toSet()
        ..addAllIfAbsentElseRemove(unwrappedIds)
    };
    selectedAssignedItemIds = {...updatedIds};
    selectedCandidateItemIds = {};
    onSelectionChanged?.call(selectedCandidateItemIds, selectedAssignedItemIds);
    notifyListeners();
  }
}

///
/// Orchestrates Selection and Drag and Drop utilities for Decendant Assignable List Items.
/// Accepts a Map<K, CandidateValue<K,V> where K is the type of the ID used and V is the item specific Value.
///
class DefaultAssignableItemListController<K, V> extends StatefulWidget {
  final AssignableItemListController<K, V> controller;
  final Widget child;

  const DefaultAssignableItemListController({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<DefaultAssignableItemListController<K, V>> createState() =>
      _DefaultAssignableItemListControllerState<K, V>();
}

class _DefaultAssignableItemListControllerState<K, V>
    extends State<DefaultAssignableItemListController<K, V>> {
  @override
  Widget build(BuildContext context) {
    return _wrapDragController(
      child: _wrapCandidateItemSelectionContainer(
          child: _wrapAssignedItemSelectionContainer(
              child: ListControllerMessenger<K, V>(
        controller: widget.controller,
        child: widget.child,
      ))),
    );
  }

  Widget _wrapDragController({required Widget child}) {
    return DragProxyController(child: child);
  }

  Widget _wrapCandidateItemSelectionContainer({required Widget child}) {
    return ItemSelectionContainer<CandidateItemIdWrapper<K>>(
      selectedItemIds: widget.controller.selectedCandidateItemIds
          .map((id) => CandidateItemIdWrapper<K>(id))
          .toSet(),
      onSelectionUpdated: widget.controller.handleCandidateSelectionUpdated,
      child: child,
    );
  }

  Widget _wrapAssignedItemSelectionContainer({required Widget child}) {
    return ItemSelectionContainer<AssignedItemIdWrapper<K>>(
      debug: true,
      selectedItemIds: widget.controller.selectedAssignedItemIds
          .map((id) => AssignedItemIdWrapper<K>(id))
          .toSet(),
      onSelectionUpdated: widget.controller.handleAssignedItemSelectionUpdated,
      child: child,
    );
  }
}

class ListControllerMessenger<K, V> extends InheritedWidget {
  final AssignableItemListController<K, V> controller;
  const ListControllerMessenger({
    super.key,
    required super.child,
    required this.controller,
  });

  static ListControllerMessenger<K, V>? maybeOf<K, V>(BuildContext context) {
    if (context.mounted == false) {
      return null;
    }

    return context
        .dependOnInheritedWidgetOfExactType<ListControllerMessenger<K, V>>();
  }

  @override
  bool updateShouldNotify(covariant ListControllerMessenger oldWidget) {
    return oldWidget.controller != controller;
  }
}

typedef AssignableItemBuilder<K, V> = Widget Function(
    BuildContext context, AssignableItem<K, V>? value, bool selected);

class CandidateDelegate<K, V> extends StatelessWidget {
  final K id;
  final int selectionIndex;
  final AssignableItemBuilder<K, V> builder;
  final AssignableItemListController<K, V>? fallbackController;

  const CandidateDelegate({
    super.key,
    required this.id,
    required this.builder,
    required this.selectionIndex,
    this.fallbackController,
  });

  @override
  Widget build(BuildContext context) {
    final listController =
        ListControllerMessenger.maybeOf<K, V>(context)?.controller ??
            fallbackController!;

    return ListenableBuilder(
        listenable: listController,
        builder: (context, _) {
          final item = listController.items[id];

          final child = builder(context, item,
              listController.selectedCandidateItemIds.contains(id));
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
      required AssignableItemListController<K, V>? controller,
      required AssignableItem<K, V>? item}) {
    if (controller == null ||
        item == null ||
        DragProxyMessenger.of(context) == null) {
      return child;
    }

    return LongPressDraggableProxy<AssignableItemDragData<K>>(
      feedback: SizedBox(width: 400, child: child),
      onDragCompleted: () => controller.handleDragEnded(),
      onDragEnd: (details) => controller.handleDragEnded(),
      onDraggableCanceled: (vel, details) => controller.handleDragEnded(),
      data: AssignableItemDragData(
          itemIds: controller.selectedCandidateItemIds.toList()),
      child: child,
    );
  }

  Widget _wrapSelectionListener({
    required Widget child,
    required AssignableItem? item,
    required int selectionIndex,
    required BuildContext context,
  }) {
    if (item == null ||
        ItemSelectionMessenger.maybeOf<CandidateItemIdWrapper<K>>(context) ==
            null) {
      return child;
    }

    return ItemSelectionListener<CandidateItemIdWrapper<K>>(
      itemId: CandidateItemIdWrapper<K>(item.id),
      index: selectionIndex,
      child: child,
    );
  }
}

typedef ItemSlotBuilder<K, V> = Widget Function(
    BuildContext context, AssignableItem<K, V>? value, bool selected);

class ItemSlot<K, V> extends StatelessWidget {
  final K? assignedItemId;
  final String slotIndexScope;
  final int slotIndex;
  final int? selectionIndex;
  final AssignableItemBuilder<K, V> builder;
  final void Function(List<K> itemIds) onItemsLanded;

  const ItemSlot({
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
    final controller =
        ListControllerMessenger.maybeOf<K, V>(context)!.controller;
    return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final item =
              assignedItemId != null ? controller.items[assignedItemId] : null;

          final child = builder(context, item,
              controller.selectedAssignedItemIds.contains(assignedItemId));
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
      required AssignableItemListController<K, V>? controller,
      required String slotIndexScope,
      required int slotIndex}) {
    if (controller == null) {
      return child;
    }

    final scopedSlotIndex =
        ScopedSlotIndex(scope: slotIndexScope, index: slotIndex);
    return Container(
      foregroundDecoration:
          controller.activatedSlotIndexes.contains(scopedSlotIndex)
              ? BoxDecoration(border: Border.all(color: Colors.green, width: 1))
              : null,
      child: child,
    );
  }

  Widget _wrapDragTarget(
      {required Widget child,
      required AssignableItemListController<K, V>? controller}) {
    return DragTargetProxy<AssignableItemDragData<K>>(
      onAcceptWithDetails: (details) {
        onItemsLanded(details.data.itemIds);
      },
      onWillAcceptWithDetails: (details) {
        controller?.handleDragOver(
            ScopedSlotIndex(scope: slotIndexScope, index: slotIndex));

        return true;
      },
      builder: (context, candidateItems, rejectedItems) {
        return child;
      },
    );
  }

  Widget _wrapDraggable(
      {required Widget child,
      required AssignableItemListController<K, V>? controller,
      required AssignableItem<K, V>? item}) {
    if (controller == null || item == null) {
      return child;
    }

    return LongPressDraggableProxy<AssignableItemDragData<K>>(
      feedback: SizedBox(width: 1200, child: child),
      onDragCompleted: () => controller.handleDragEnded(),
      onDragEnd: (details) => controller.handleDragEnded(),
      onDraggableCanceled: (vel, details) => controller.handleDragEnded(),
      data: AssignableItemDragData<K>(
          itemIds: controller.selectedAssignedItemIds.toList()),
      child: child,
    );
  }

  Widget _wrapSelectionListener(
      {required Widget child,
      required AssignableItem? item,
      required int? selectionIndex}) {
    if (item == null || selectionIndex == null) {
      return child;
    }

    return ItemSelectionListener<AssignedItemIdWrapper<K>>(
      itemId: AssignedItemIdWrapper<K>(item.id),
      index: selectionIndex,
      child: child,
    );
  }
}

class ScopedSlotIndex {
  final String scope;
  final int index;

  ScopedSlotIndex({
    required this.scope,
    required this.index,
  });

  @override
  bool operator ==(Object other) {
    return other is ScopedSlotIndex &&
        other.scope == scope &&
        other.index == index;
  }

  @override
  int get hashCode => scope.hashCode ^ index.hashCode;
}

class AssignableItem<K, V> {
  final K id;
  final V item;

  AssignableItem({
    required this.id,
    required this.item,
  });
}

class CandidateItemIdWrapper<K> {
  final K id;

  CandidateItemIdWrapper(this.id);

  @override
  bool operator ==(Object other) {
    return other is CandidateItemIdWrapper && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class AssignedItemIdWrapper<K> {
  final K id;

  AssignedItemIdWrapper(this.id);

  @override
  bool operator ==(Object other) {
    return other is AssignedItemIdWrapper && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class AssignableItemDragData<K> {
  final List<K> itemIds;

  AssignableItemDragData({
    required this.itemIds,
  });
}
