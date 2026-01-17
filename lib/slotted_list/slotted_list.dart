import 'package:flutter/widgets.dart';

typedef CandidateBuilder = Widget Function(BuildContext context, String itemId);
typedef SlottedBuilder = Widget Function(BuildContext context, String itemId);

class CandidateData {
  final CandidateBuilder candidateBuilder;
  final SlottedBuilder slottedBuilder;
  final String itemId;

  CandidateData({
    required this.candidateBuilder,
    required this.slottedBuilder,
    required this.itemId,
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
    return widget.data.candidateBuilder(context, widget.data.itemId);
  }
}

class Slot extends StatefulWidget {
  final int index;
  final Widget Function(BuildContext context, int index, Widget? candidate)
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
    return widget.builder(
        context,
        widget.index,
        widget.assignedItemId == null
            ? null
            : SlottedListMessenger.maybeOf(context)!
                .getCandidateData(widget.assignedItemId!)
                ?.slottedBuilder(context, widget.assignedItemId!));
  }
}

class SlottedListController extends StatefulWidget {
  final Widget child;

  const SlottedListController({
    super.key,
    required this.child,
  });

  @override
  State<SlottedListController> createState() => _SlottedListControllerState();
}

class _SlottedListControllerState extends State<SlottedListController> {
  Map<String, CandidateData> _candidates = {};

  @override
  Widget build(BuildContext context) {
    return SlottedListMessenger(
      onRegisterCandidate: _handleCandidateRegistration,
      onGetCandidateData: _handleCandidateDataRequest,
      child: widget.child,
    );
  }

  CandidateData? _handleCandidateDataRequest(String id) {
    return _candidates[id];
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

  const SlottedListMessenger({
    super.key,
    required this.onRegisterCandidate,
    required this.onGetCandidateData,
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
        oldWidget.onGetCandidateData != onGetCandidateData;
  }
}
