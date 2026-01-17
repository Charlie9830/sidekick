import 'package:flutter/widgets.dart';
import 'package:sidekick/extension_methods/all_all_if_absent_else_remove.dart';
import 'package:sidekick/item_selection/item_selection_container.dart';
import 'package:sidekick/item_selection/item_selection_listener.dart';

typedef CandidateBuilder = Widget Function(BuildContext context, String itemId);
typedef SlottedBuilder = Widget Function(BuildContext context, String itemId);

class CandidateData {
  final CandidateBuilder candidateBuilder;
  final SlottedBuilder slottedContentsBuilder;
  final String itemId;
  final int candidateSelectionIndex;
  final int slottedSelectionIndex;

  CandidateData({
    required this.candidateBuilder,
    required this.slottedContentsBuilder,
    required this.itemId,
    required this.candidateSelectionIndex,
    required this.slottedSelectionIndex,
  });
}

class CandidateListItem extends StatefulWidget {
  final CandidateData data;

  const CandidateListItem({
    super.key,
    required this.data,
  });

  @override
  State<CandidateListItem> createState() => _CandidateListItemState();
}

class _CandidateListItemState extends State<CandidateListItem> {
  @override
  void didChangeDependencies() {
    SlottedListMessenger.maybeOf(context)!.registerCandiate(widget.data);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return ItemSelectionListener<_CandidateIdWrapper>(
        itemId: _CandidateIdWrapper(widget.data.itemId),
        index: widget.data.candidateSelectionIndex,
        child: widget.data.candidateBuilder(
          context,
          widget.data.itemId,
        ));
  }
}

class Slot extends StatefulWidget {
  final int index;
  final Widget Function(
          BuildContext context, int index, Widget? candidate, bool selected)
      builder;
  final String? assignedItemId;

  const Slot({
    super.key,
    required this.index,
    required this.builder,
    required this.assignedItemId,
  });

  @override
  State<Slot> createState() => _SlotState();
}

class _SlotState extends State<Slot> {
  @override
  Widget build(BuildContext context) {
    final candidateData = widget.assignedItemId == null
        ? null
        : SlottedListMessenger.maybeOf(context)!
            .getCandidateData(widget.assignedItemId!);

    final selected = widget.assignedItemId == null
        ? false
        : SlottedListMessenger.maybeOf(context)!
            .selectedSlottedItemIds
            .contains(widget.assignedItemId);

    return _wrapSelectionListener(
      itemId: widget.assignedItemId,
      selectionIndex: candidateData?.slottedSelectionIndex,
      child: widget.builder(
        context,
        widget.index,
        candidateData?.slottedContentsBuilder(context, widget.assignedItemId!),
        selected,
      ),
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

  @override
  Widget build(BuildContext context) {
    return ItemSelectionContainer<_SlottedItemIdWrapper>(
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
          selectedCandidateIds: widget.selectedCandidateIds,
          selectedSlottedItemIds: widget.selectedSlottedItemIds,
          child: widget.child,
        ),
      ),
    );
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
  final CandidateData? Function(String id) onGetCandidateData;
  final Set<String> selectedCandidateIds;
  final Set<String> selectedSlottedItemIds;

  const SlottedListMessenger({
    super.key,
    required this.onRegisterCandidate,
    required this.onGetCandidateData,
    required this.selectedCandidateIds,
    required this.selectedSlottedItemIds,
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

  CandidateData? getCandidateData(String id) {
    return onGetCandidateData(id);
  }

  @override
  bool updateShouldNotify(SlottedListMessenger oldWidget) {
    return oldWidget.onRegisterCandidate != onRegisterCandidate ||
        oldWidget.onGetCandidateData != onGetCandidateData ||
        oldWidget.selectedCandidateIds != selectedCandidateIds ||
        oldWidget.selectedSlottedItemIds != selectedSlottedItemIds;
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
