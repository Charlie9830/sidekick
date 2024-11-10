// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/cable_model.dart';

class FoldedCable {
  final CableModel cable;
  final List<CableModel> children;

  FoldedCable(this.cable, this.children);

  FoldedCable copyWith({
    CableModel? cable,
    List<CableModel>? children,
  }) {
    return FoldedCable(
      cable ?? this.cable,
      children ?? this.children,
    );
  }

  /// Will return a list of [FoldedCable] where relevant child cables are folded into their parent cables. Children that have been folded
  /// will not appear in the top level collection.
  static List<FoldedCable> foldCablesIntoSneaks(Iterable<CableModel> cables) {
    final cablesByParentMultiId = cables
        .where((cable) => cable.parentMultiId.isNotEmpty)
        .groupListsBy((cable) => cable.parentMultiId);

    return cables
        .map((cable) =>
            FoldedCable(cable, cablesByParentMultiId[cable.uid] ?? []))
        .where((foldedCable) => foldedCable.cable.parentMultiId.isEmpty)
        .toList();
  }

  @override
  String toString() {
    return 'FoldedCable(cable: ${cable.uid}, children: ${children.map((child) => child.uid)} )';
  }
}
