import 'dart:math';

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';

class SlotItem<T> {
  final String id;
  final int itemIndex;
  final T data;
  final List<T> associatedData;

  SlotItem({
    required this.id,
    required this.data,
    required this.associatedData,
    required this.itemIndex,
  });
}

class _SlotItemWrapper<T extends SlotItem> extends StatelessWidget {
  final Widget child;
  final bool isDragHoveringOver;
  final bool isSelected;
  final void Function(int hoveringItemCount) onHoverEnter;
  final void Function() onHoverLeave;
  final void Function(T data) onItemsLanded;

  const _SlotItemWrapper({
    super.key,
    required this.child,
    required this.isDragHoveringOver,
    required this.isSelected,
    required this.onHoverEnter,
    required this.onHoverLeave,
    required this.onItemsLanded,
  });

  @override
  Widget build(BuildContext context) {
    return DragTargetProxy<T>(
      onWillAcceptWithDetails: (details) {
        onHoverEnter(details.data.associatedData.length);
        return true;
      },
      onAcceptWithDetails: (details) {
        onHoverLeave();
        onItemsLanded(details.data);
      },
      onLeave: (details) => onHoverLeave(),
      builder: (BuildContext context, List<T?> candidateData,
          List<dynamic> rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.border : null,
          ),
          foregroundDecoration: isDragHoveringOver
              ? const BoxDecoration(
                  border: BoxBorder.fromBorderSide(
                    BorderSide(
                      color: Colors.green,
                      width: 1,
                    ),
                  ),
                )
              : null,
          child: child,
        );
      },
    );
  }
}

class SlotList<T extends SlotItem> extends StatefulWidget {
  final int slotCount;
  final Map<int, T?> items;
  final Widget Function(BuildContext context, int index) vacantBuilder;
  final Widget Function(BuildContext context, int index, String id)
      occupiedBuilder;

  const SlotList({
    super.key,
    required this.items,
    required this.slotCount,
    required this.vacantBuilder,
    required this.occupiedBuilder,
  });

  @override
  State<SlotList> createState() => _SlotListState();
}

class _SlotListState extends State<SlotList> {
  Set<int> _hoveredOverIndexes = {};

  @override
  Widget build(BuildContext context) {
    assert(SlotListMessenger.maybeOf(context) != null,
        'Invalid Ancestry: A [SlotListController] must be provided as an ancestor to this [SlotList]');

    return ListView.builder(
      itemCount: max(widget.slotCount, widget.items.length),
      itemBuilder: (context, index) {
        final slotItem = widget.items[index];
        return _wrapSelectionListener(
            slotItem,
            _SlotItemWrapper(
                isDragHoveringOver: _hoveredOverIndexes.contains(index),
                isSelected: slotItem == null
                    ? false
                    : SlotListMessenger.of(context)
                        .selectedItemIds
                        .contains(slotItem.id),
                onHoverEnter: (hoveringItemCount) =>
                    setState(() => _hoveredOverIndexes = {
                          ...List<int>.generate(hoveringItemCount,
                              (generatorIndex) => index + generatorIndex),
                        }),
                onHoverLeave: () => setState(() => _hoveredOverIndexes =
                    _hoveredOverIndexes.toSet()..remove(index)),
                onItemsLanded: (data) {
                  // TODO Implement This.
                },
                child: slotItem == null
                    ? widget.vacantBuilder(context, index)
                    : _wrapInnerDragProxy(
                        item: slotItem,
                        child: widget.occupiedBuilder(
                            context, index, slotItem.id))));
      },
    );
  }

  Widget _wrapInnerDragProxy({
    required Widget child,
    required SlotItem item,
  }) {
    return LongPressDraggableProxy<SlotItem>(
      data: item,
      childWhenDragging: child,
      feedback: Opacity(
        opacity: 0.25,
        child: SizedBox(
          width: 600,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

Widget _wrapSelectionListener(SlotItem? item, Widget child) {
  if (item == null) {
    return child;
  }

  return ItemSelectionListener<String>(
    itemId: item.id,
    index: item.itemIndex,
    child: child,
  );
}

class SlotableCandidateList extends StatelessWidget {
  const SlotableCandidateList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class SlotListController<T extends SlotItem> extends StatefulWidget {
  final Widget child;
  const SlotListController({
    super.key,
    required this.child,
  });

  @override
  State<SlotListController> createState() => _SlotListControllerState();
}

class _SlotListControllerState<T extends SlotItem>
    extends State<SlotListController> {
  Set<String> _selectedItemIds = {};

  @override
  Widget build(BuildContext context) {
    return ItemSelectionContainer<String>(
      selectedItemIds: _selectedItemIds,
      onSelectionUpdated: (updateType, ids) {
        final newValue = switch (updateType) {
          UpdateType.overwrite => ids.toSet(),
          UpdateType.addIfAbsentElseRemove => _selectedItemIds.toSet()
            ..addAllIfAbsentElseRemove(ids),
        };

        setState(() {
          _selectedItemIds = newValue;
        });
      },
      child: SlotListMessenger<T>(
        selectedItemIds: _selectedItemIds,
        child: widget.child,
      ),
    );
  }
}

class SlotListMessenger<T extends SlotItem> extends InheritedWidget {
  final Set<String> selectedItemIds;

  const SlotListMessenger({
    super.key,
    required Widget child,
    required this.selectedItemIds,
  }) : super(child: child);

  static SlotListMessenger of<T extends SlotItem>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SlotListMessenger<T>>()!;
  }

  static SlotListMessenger? maybeOf<T extends SlotItem>(BuildContext context) {
    if (context.mounted == false) {
      return null;
    }

    return context.dependOnInheritedWidgetOfExactType<SlotListMessenger<T>>();
  }

  @override
  bool updateShouldNotify(SlotListMessenger oldWidget) {
    if (oldWidget.selectedItemIds != selectedItemIds) {
      return true;
    }
    return false;
  }
}
