// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';

///
/// Orchestrates Selection and Drag and Drop utilities for Decendant Assignable List Items.
/// Accepts a Map<K, CandidateValue<K,V> where K is the type of the ID used and V is the item specific Value.
///
class AssignableItemListController<K, V> extends StatefulWidget {
  final Map<K, AssignableItem<K, V>> items;
  final Set<K> selectedCandidateItemIds;
  final Set<K> selectedAssignedItemIds;
  final void Function(Set<K> ids) onSelectedCandidateIdsChanged;
  final void Function(Set<K> ids) onSelectedAssignedIdsChanged;
  final Widget child;

  const AssignableItemListController({
    super.key,
    required this.items,
    required this.child,
    required this.onSelectedCandidateIdsChanged,
    required this.selectedCandidateItemIds,
    required this.selectedAssignedItemIds,
    required this.onSelectedAssignedIdsChanged,
  });

  @override
  State<AssignableItemListController<K, V>> createState() =>
      _AssignableItemListControllerState<K, V>();
}

class _AssignableItemListControllerState<K, V>
    extends State<AssignableItemListController<K, V>> {
  Set<ScopedSlotIndex> _activatedSlotIndexes = {};

  @override
  Widget build(BuildContext context) {
    return _wrapDragController(
      child: _wrapCandidateItemSelectionContainer(
          child: _wrapAssignedItemSelectionContainer(
              child: ListControllerMessenger<K, V>(
        items: widget.items,
        selectedAssignedIds: widget.selectedAssignedItemIds,
        selectedCandidateIds: widget.selectedCandidateItemIds,
        activatedSlotIndexes: _activatedSlotIndexes,
        onDragStarted: _handleDragStarted,
        onDragOver: _handleDragOver,
        child: widget.child,
      ))),
    );
  }

  void _handleDragOver(ScopedSlotIndex slotIndex) {
    final selectedItemCount = max(widget.selectedAssignedItemIds.length,
        widget.selectedCandidateItemIds.length);

    final activatedSlotIndexes = List.generate(
        selectedItemCount,
        (index) => ScopedSlotIndex(
              scope: slotIndex.scope,
              index: slotIndex.index + index,
            ));

    setState(() {
      _activatedSlotIndexes = activatedSlotIndexes.toSet();
    });
  }

  void _handleDragStarted(AssignableItem<K, V> sourceItem) {}

  Widget _wrapDragController({required Widget child}) {
    return DragProxyController(child: child);
  }

  Widget _wrapCandidateItemSelectionContainer({required Widget child}) {
    return ItemSelectionContainer<CandidateItemIdWrapper<K>>(
      selectedItemIds: widget.selectedCandidateItemIds
          .map((id) => CandidateItemIdWrapper<K>(id))
          .toSet(),
      onSelectionUpdated: _handleCandidateSelectionUpdated,
      child: child,
    );
  }

  Widget _wrapAssignedItemSelectionContainer({required Widget child}) {
    return ItemSelectionContainer<AssignedItemIdWrapper<K>>(
      debug: true,
      selectedItemIds: widget.selectedAssignedItemIds
          .map((id) => AssignedItemIdWrapper<K>(id))
          .toSet(),
      onSelectionUpdated: _handleAssignedItemSelectionUpdated,
      child: child,
    );
  }

  void _handleCandidateSelectionUpdated(
      UpdateType type, Set<CandidateItemIdWrapper<K>> wrappedIds) {
    final unwrappedIds = wrappedIds.map((wrapper) => wrapper.id).toSet();
    final updatedIds = switch (type) {
      UpdateType.overwrite => unwrappedIds.toSet(),
      UpdateType.addIfAbsentElseRemove => widget.selectedCandidateItemIds
        ..addAllIfAbsentElseRemove(unwrappedIds)
    };

    widget.onSelectedCandidateIdsChanged(updatedIds);
  }

  void _handleAssignedItemSelectionUpdated(
      UpdateType type, Set<AssignedItemIdWrapper<K>> wrappedItemIds) {
    final unwrappedIds = wrappedItemIds.map((wrapper) => wrapper.id).toSet();
    final updatedIds = switch (type) {
      UpdateType.overwrite => unwrappedIds.toSet(),
      UpdateType.addIfAbsentElseRemove => widget.selectedAssignedItemIds.toSet()
        ..addAllIfAbsentElseRemove(unwrappedIds)
    };

    widget.onSelectedAssignedIdsChanged(updatedIds);
  }
}

class ListControllerMessenger<K, V> extends InheritedWidget {
  final Map<K, AssignableItem<K, V>> items;
  final Set<K> selectedCandidateIds;
  final Set<K> selectedAssignedIds;
  final void Function(AssignableItem<K, V> item) onDragStarted;
  final void Function(ScopedSlotIndex slotIndex) onDragOver;
  final Set<ScopedSlotIndex> activatedSlotIndexes;

  const ListControllerMessenger({
    super.key,
    required super.child,
    required this.items,
    required this.selectedAssignedIds,
    required this.selectedCandidateIds,
    required this.onDragStarted,
    required this.onDragOver,
    required this.activatedSlotIndexes,
  });

  static ListControllerMessenger<K, V>? maybeOf<K, V>(BuildContext context) {
    if (context.mounted == false) {
      return null;
    }

    return context
            .dependOnInheritedWidgetOfExactType<ListControllerMessenger<K, V>>()
        as ListControllerMessenger<K, V>;
  }

  @override
  bool updateShouldNotify(covariant ListControllerMessenger oldWidget) {
    return oldWidget.items != items ||
        oldWidget.selectedAssignedIds != selectedAssignedIds ||
        oldWidget.selectedCandidateIds != selectedCandidateIds ||
        oldWidget.activatedSlotIndexes != activatedSlotIndexes;
  }

  AssignableItem<K, V>? fetchItem(K id) {
    return items[id];
  }

  void notifyDragOver(ScopedSlotIndex index) {
    onDragOver(index);
  }

  void notifyDragStarted(AssignableItem<K, V> item) {
    onDragStarted(item);
  }
}

typedef CandidateBuilder<K, V> = Widget Function(
    BuildContext context, AssignableItem<K, V>? value, bool selected);

class CandidateItem<K, V> extends StatelessWidget {
  final K id;
  final CandidateBuilder<K, V> builder;

  const CandidateItem({super.key, required this.id, required this.builder});

  @override
  Widget build(BuildContext context) {
    final controller = ListControllerMessenger.maybeOf<K, V>(context);
    final item = controller?.fetchItem(id) as AssignableItem<K, V>;

    final child = builder(context, item as AssignableItem<K, V>?,
        controller?.selectedCandidateIds.contains(id) ?? false);

    return _wrapSelectionListener(
      item: item,
      child: _wrapDraggable(child: child, controller: controller, item: item),
    );
  }

  Widget _wrapDraggable(
      {required Widget child,
      required ListControllerMessenger<K, V>? controller,
      required AssignableItem<K, V>? item}) {
    if (controller == null || item == null) {
      return child;
    }

    return LongPressDraggableProxy<AssignableItemDragData>(
      feedback: SizedBox(width: 400, child: child),
      onDragStarted: () => controller.onDragStarted(item),
      child: child,
    );
  }

  Widget _wrapSelectionListener(
      {required Widget child, required AssignableItem? item}) {
    if (item == null) {
      return child;
    }

    return ItemSelectionListener<CandidateItemIdWrapper<K>>(
      itemId: CandidateItemIdWrapper<K>(item.id),
      index: item.candidateSelectionIndex,
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
  final CandidateBuilder<K, V> builder;
  final void Function(List<V> items) onItemsLanded;

  const ItemSlot({
    super.key,
    required this.assignedItemId,
    required this.builder,
    required this.slotIndex,
    required this.onItemsLanded,
    this.slotIndexScope = '',
  });

  @override
  Widget build(BuildContext context) {
    final controller = ListControllerMessenger.maybeOf<K, V>(context);
    final item = assignedItemId != null
        ? controller?.fetchItem(assignedItemId as K) as AssignableItem<K, V>
        : null;

    final child = builder(context, item,
        controller?.selectedAssignedIds.contains(assignedItemId) ?? false);

    return _wrapActivatedBorder(
      controller: controller,
      slotIndex: slotIndex,
      slotIndexScope: slotIndexScope,
      child: _wrapDragTarget(
        controller: controller,
        child: _wrapSelectionListener(
          item: item,
          child:
              _wrapDraggable(child: child, controller: controller, item: item),
        ),
      ),
    );
  }

  Widget _wrapActivatedBorder(
      {required Widget child,
      required ListControllerMessenger<K, V>? controller,
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
      required ListControllerMessenger<K, V>? controller}) {
    return DragTargetProxy<AssignableItemDragData<K, V>>(
        onAcceptWithDetails: (details) {
      onItemsLanded(details.data.items.map((item) => item.item).toList());
    }, onWillAcceptWithDetails: (details) {
      controller?.notifyDragOver(
          ScopedSlotIndex(scope: slotIndexScope, index: slotIndex));

      return true;
    }, builder: (context, candidateItems, rejectedItems) {
      return child;
    });
  }

  Widget _wrapDraggable(
      {required Widget child,
      required ListControllerMessenger<K, V>? controller,
      required AssignableItem<K, V>? item}) {
    if (controller == null || item == null) {
      return child;
    }

    return LongPressDraggableProxy<AssignableItemDragData>(
      feedback: SizedBox(width: 400, child: child),
      onDragStarted: () => controller.onDragStarted(item),
      child: child,
    );
  }

  Widget _wrapSelectionListener(
      {required Widget child, required AssignableItem? item}) {
    if (item == null) {
      return child;
    }

    return ItemSelectionListener<AssignedItemIdWrapper<K>>(
      itemId: AssignedItemIdWrapper<K>(item.id),
      index: item.assignedSelectionIndex,
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
  final int candidateSelectionIndex;
  final int? assignedSelectionIndex;

  AssignableItem({
    required this.id,
    required this.item,
    required this.candidateSelectionIndex,
    required this.assignedSelectionIndex,
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

class AssignableItemDragData<K, V> {
  final List<AssignableItem<K, V>> items;

  AssignableItemDragData({
    required this.items,
  });
}
