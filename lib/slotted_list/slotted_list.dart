import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';

class SlotId {
  final String parentId;
  final int slotIndex;

  SlotId({
    required this.parentId,
    required this.slotIndex,
  });

  @override
  bool operator ==(Object other) {
    return other is SlotId &&
        other.parentId == parentId &&
        other.slotIndex == slotIndex;
  }

  @override
  int get hashCode => parentId.hashCode ^ slotIndex.hashCode;
}

typedef CandidateBuilder = Widget Function(BuildContext context);
typedef SlottedBuilder = Widget Function(BuildContext context);

class CandidateData {
  final CandidateBuilder candidateBuilder;
  final String itemId;
  final int candidateSelectionIndex;

  CandidateData({
    required this.candidateBuilder,
    required this.itemId,
    required this.candidateSelectionIndex,
  });
}

sealed class _DragData {
  final List<CandidateData> draggingCandidates;

  _DragData(this.draggingCandidates);
}

class _CandidateDragData extends _DragData {
  _CandidateDragData(super.draggingCandidates);
}

class _SlottedItemDragData extends _DragData {
  _SlottedItemDragData(super.draggingCandidates);
}

class CandidateListItem extends StatefulWidget {
  final CandidateData configuration;
  final double feedbackOpacity;
  final BoxConstraints? feedbackConstraints;

  const CandidateListItem({
    super.key,
    required this.configuration,
    this.feedbackConstraints,
    this.feedbackOpacity = 0.25,
  });

  @override
  State<CandidateListItem> createState() => _CandidateListItemState();
}

class _CandidateListItemState extends State<CandidateListItem> {
  @override
  void didChangeDependencies() {
    SlottedListMessenger.maybeOf(context)!
        .registerCandiate(widget.configuration);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final controller = SlottedListMessenger.maybeOf(context)!;
    final selectedCandidates = controller.getAllSelectedCandidateData();

    return LongPressDraggableProxy<_CandidateDragData>(
      data: _CandidateDragData(selectedCandidates),
      onDragEnd: (details) => controller.notifyCandidateDragEnd(),
      feedback: Column(
        children: selectedCandidates.map((candidate) {
          final candidateWidget = candidate.candidateBuilder(context);

          return ConstrainedBox(
            constraints: widget.feedbackConstraints ?? const BoxConstraints(),
            child: Opacity(
              opacity: widget.feedbackOpacity,
              child: candidateWidget,
            ),
          );
        }).toList(),
      ),
      child: ItemSelectionListener<_CandidateIdWrapper>(
          itemId: _CandidateIdWrapper(widget.configuration.itemId),
          index: widget.configuration.candidateSelectionIndex,
          child: widget.configuration.candidateBuilder(
            context,
          )),
    );
  }
}

typedef SlotBuilder = Widget Function(
    BuildContext context, int slotIndex, bool selected);

class Slot extends StatefulWidget {
  final int slotIndex;
  final int? selectionIndex;
  final String parentId;
  final Widget Function(BuildContext context, int index, bool selected) builder;
  final void Function(List<CandidateData> candidates) onCandidatesLanded;
  final void Function(List<CandidateData> candidates) onCandidatesRepositioned;
  final String? assignedItemId;
  final double feedbackOpacity;
  final BoxConstraints feedbackConstraints;

  const Slot({
    super.key,
    this.parentId = '',
    required this.slotIndex,
    required this.builder,
    required this.assignedItemId,
    required this.onCandidatesLanded,
    required this.onCandidatesRepositioned,
    required this.selectionIndex,
    this.feedbackOpacity = 0.25,
    this.feedbackConstraints = const BoxConstraints(),
  });

  @override
  State<Slot> createState() => _SlotState();
}

class _SlotState extends State<Slot> {
  @override
  Widget build(BuildContext context) {
    final controller = SlottedListMessenger.maybeOf(context)!;

    final candidateData = widget.assignedItemId == null
        ? null
        : controller.getCandidateData(widget.assignedItemId!);

    final selected = widget.assignedItemId == null
        ? false
        : controller.selectedSlottedItemIds.contains(widget.assignedItemId);

    return DragTargetProxy<_DragData>(
      onAcceptWithDetails: (details) {
        switch (details.data) {
          case _CandidateDragData():
            widget.onCandidatesLanded(details.data.draggingCandidates);
          case _SlottedItemDragData():
            widget.onCandidatesRepositioned(details.data.draggingCandidates);
        }
      },
      onWillAcceptWithDetails: (details) {
        controller.notifySlotDragEnter(details.data.draggingCandidates.length,
            widget.parentId, widget.slotIndex);
        return true;
      },
      onLeave: (details) {
        controller.notifySlotDragLeave(widget.parentId, widget.slotIndex);
      },
      builder: (context, candidateItems, rejectedItems) {
        return _wrapDragOverBorder(
          showBorder: controller.hoveredSlotIds.contains(
              SlotId(parentId: widget.parentId, slotIndex: widget.slotIndex)),
          child: _wrapSelectionListener(
            itemId: widget.assignedItemId,
            selectionIndex: widget.selectionIndex,
            child: _wrapDraggable(
              controller: controller,
              candidateData: candidateData,
              child: widget.builder(
                context,
                widget.slotIndex,
                selected,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _wrapDraggable(
      {required Widget child,
      required CandidateData? candidateData,
      required SlottedListMessenger controller}) {
    if (candidateData == null) {
      return child;
    }

    return LongPressDraggable<_SlottedItemDragData>(
      data: _SlottedItemDragData(
        controller.getAllSelectedSlottedItemsData(),
      ),
      onDragCompleted: () => controller.notifyCandidateDragEnd(),
      feedback: ConstrainedBox(
          constraints: widget.feedbackConstraints,
          child: Opacity(opacity: widget.feedbackOpacity, child: child)),
      child: child,
    );
  }

  Widget _wrapDragOverBorder(
      {required Widget child, required bool showBorder}) {
    return Container(
      foregroundDecoration: BoxDecoration(
        border: showBorder ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: child,
    );
  }

  Widget _wrapSelectionListener(
      {required String? itemId,
      required int? selectionIndex,
      required Widget child}) {
    if (itemId == null || selectionIndex == null) {
      return child;
    }

    return ItemSelectionListener<_SlottedItemIdWrapper>(
        itemId: _SlottedItemIdWrapper(itemId),
        index: selectionIndex,
        child: child);
  }
}

class SlottedListController extends StatefulWidget {
  final Widget child;
  final Set<String> selectedCandidateIds;
  final Set<String> selectedSlottedItemIds;
  final void Function(Set<String> ids) onSelectedCandidateIdsChanged;
  final void Function(Set<String> ids) onSelectedSlottedItemIdsChanged;

  const SlottedListController({
    super.key,
    required this.child,
    required this.selectedCandidateIds,
    required this.selectedSlottedItemIds,
    required this.onSelectedCandidateIdsChanged,
    required this.onSelectedSlottedItemIdsChanged,
  });

  @override
  State<SlottedListController> createState() => _SlottedListControllerState();
}

class _SlottedListControllerState extends State<SlottedListController> {
  Map<String, CandidateData> _candidates = {};
  Set<SlotId> _hoveredSlotIds = {};

  @override
  Widget build(BuildContext context) {
    return DragProxyController(
      child: ItemSelectionContainer<_SlottedItemIdWrapper>(
        selectedItemIds: widget.selectedSlottedItemIds
            .map((id) => _SlottedItemIdWrapper(id))
            .toSet(),
        onSelectionUpdated: _handleSlottedItemSelectionUpdated,
        child: ItemSelectionContainer<_CandidateIdWrapper>(
          selectedItemIds: widget.selectedCandidateIds
              .map((id) => _CandidateIdWrapper(id))
              .toSet(),
          onSelectionUpdated: _handleCandidateSelectionUpdated,
          child: SlottedListMessenger(
            onRegisterCandidate: _handleCandidateRegistration,
            onGetCandidateData: _handleCandidateDataRequest,
            onGetAllSelectedCandidateData:
                _handleGetAllSelectedCandidateDataRequest,
            onGetAllSelectedSlottedItemsData:
                _handleGetAllSelectedSlottedItemsRequest,
            selectedCandidateIds: widget.selectedCandidateIds,
            selectedSlottedItemIds: widget.selectedSlottedItemIds,
            onSlotDragEnter: _handleSlotDragEnter,
            onSlotDragLeave: _handleSlotDragLeave,
            hoveredSlotIds: _hoveredSlotIds,
            onCandidateDragEnd: _handleCandidateDragEnd,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _handleCandidateDragEnd() {
    setState(() => _hoveredSlotIds = {});
  }

  void _handleSlotDragEnter(
      int draggingItemCount, String parentId, int slotIndex) {
    final hoveredSlotIds = List<SlotId>.generate(draggingItemCount,
        (index) => SlotId(parentId: parentId, slotIndex: index + slotIndex));

    setState(() => _hoveredSlotIds = hoveredSlotIds.toSet());
  }

  void _handleSlotDragLeave(String parentId, int slotIndex) {
    final hoveredSlotIds = _hoveredSlotIds.toSet()
      ..remove(SlotId(parentId: parentId, slotIndex: slotIndex));

    setState(() => _hoveredSlotIds = hoveredSlotIds);
  }

  List<CandidateData> _handleGetAllSelectedCandidateDataRequest() {
    return widget.selectedCandidateIds
        .map((id) => _handleCandidateDataRequest(id))
        .nonNulls
        .toList();
  }

  List<CandidateData> _handleGetAllSelectedSlottedItemsRequest() {
    return widget.selectedSlottedItemIds
        .map((id) => _handleCandidateDataRequest(id))
        .nonNulls
        .toList();
  }

  CandidateData? _handleCandidateDataRequest(String id) {
    return _candidates[id];
  }

  void _handleCandidateSelectionUpdated(
      UpdateType type, Set<_CandidateIdWrapper> candidateIds) {
    final ids = candidateIds.map((wrapper) => wrapper.id).toSet();
    final updatedIds = switch (type) {
      UpdateType.overwrite => ids.toSet(),
      UpdateType.addIfAbsentElseRemove => widget.selectedCandidateIds.toSet()
        ..addAllIfAbsentElseRemove(ids)
    };

    widget.onSelectedCandidateIdsChanged(updatedIds);
  }

  void _handleSlottedItemSelectionUpdated(
      UpdateType type, Set<_SlottedItemIdWrapper> slottedItemIds) {
    final ids = slottedItemIds.map((wrapper) => wrapper.id).toSet();
    final updatedIds = switch (type) {
      UpdateType.overwrite => ids.toSet(),
      UpdateType.addIfAbsentElseRemove => widget.selectedSlottedItemIds.toSet()
        ..addAllIfAbsentElseRemove(ids)
    };

    widget.onSelectedSlottedItemIdsChanged(updatedIds);
  }

  void _handleCandidateRegistration(CandidateData data) {
    final updatedCandidates = Map<String, CandidateData>.from(_candidates)
      ..addAll({data.itemId: data});

    _candidates = updatedCandidates;
  }
}

class SlottedListMessenger extends InheritedWidget {
  final void Function(CandidateData data) onRegisterCandidate;
  final List<CandidateData> Function() onGetAllSelectedCandidateData;
  final List<CandidateData> Function() onGetAllSelectedSlottedItemsData;
  final CandidateData? Function(String id) onGetCandidateData;
  final Set<String> selectedCandidateIds;
  final Set<String> selectedSlottedItemIds;
  final void Function(int draggingItemCount, String parentId, int index)
      onSlotDragEnter;
  final void Function(String parentId, int index) onSlotDragLeave;
  final void Function() onCandidateDragEnd;
  final Set<SlotId> hoveredSlotIds;

  const SlottedListMessenger({
    super.key,
    required this.onRegisterCandidate,
    required this.onGetCandidateData,
    required this.selectedCandidateIds,
    required this.selectedSlottedItemIds,
    required this.onGetAllSelectedCandidateData,
    required this.onSlotDragEnter,
    required this.onSlotDragLeave,
    required this.hoveredSlotIds,
    required this.onCandidateDragEnd,
    required this.onGetAllSelectedSlottedItemsData,
    required Widget child,
  }) : super(child: child);

  static SlottedListMessenger? maybeOf<T>(BuildContext context) {
    if (context.mounted == false) {
      return null;
    }

    return context.dependOnInheritedWidgetOfExactType<SlottedListMessenger>();
  }

  void registerCandiate(CandidateData data) {
    onRegisterCandidate(data);
  }

  void notifySlotDragEnter(int draggingItemCount, String parentId, int index) {
    onSlotDragEnter(draggingItemCount, parentId, index);
  }

  void notifySlotDragLeave(String parentId, int index) {
    onSlotDragLeave(parentId, index);
  }

  void notifyCandidateDragEnd() {
    onCandidateDragEnd();
  }

  List<CandidateData> getAllSelectedSlottedItemsData() {
    return onGetAllSelectedSlottedItemsData();
  }

  List<CandidateData> getAllSelectedCandidateData() {
    return onGetAllSelectedCandidateData();
  }

  CandidateData? getCandidateData(String id) {
    return onGetCandidateData(id);
  }

  @override
  bool updateShouldNotify(SlottedListMessenger oldWidget) {
    return oldWidget.onRegisterCandidate != onRegisterCandidate ||
        oldWidget.onGetCandidateData != onGetCandidateData ||
        oldWidget.selectedCandidateIds != selectedCandidateIds ||
        oldWidget.selectedSlottedItemIds != selectedSlottedItemIds ||
        oldWidget.hoveredSlotIds != hoveredSlotIds;
  }
}

class _CandidateIdWrapper {
  final String id;

  _CandidateIdWrapper(this.id);

  @override
  bool operator ==(Object other) {
    return other is _CandidateIdWrapper && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class _SlottedItemIdWrapper {
  final String id;

  _SlottedItemIdWrapper(this.id);

  @override
  bool operator ==(Object other) {
    return other is _SlottedItemIdWrapper && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
