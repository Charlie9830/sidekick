import 'package:collection/collection.dart';
import 'package:sidekick/redux/models/cable_model.dart';

/// Represents a Parent Multi cable with it's children attached to it. If no Children are attached then it is just a normal cable.
class CableFamily {
  final CableModel parent;
  final List<CableModel> children;

  CableFamily(this.parent, this.children);

  CableFamily copyWith({
    CableModel? parent,
    List<CableModel>? children,
  }) {
    return CableFamily(
      parent ?? this.parent,
      children ?? this.children,
    );
  }

  /// Will return a list of [CableFamily] where relevant child cables are folded into their parent cables.
  /// Children that have been folded will not appear in the top level collection.
  static List<CableFamily> createFamilies(Iterable<CableModel> cables) {
    final childrenByParentMultiId = cables
        .where((cable) => cable.parentMultiId.isNotEmpty)
        .groupListsBy((cable) => cable.parentMultiId);

    return cables
        .map((cable) =>
            CableFamily(cable, childrenByParentMultiId[cable.uid] ?? []))
        .where((foldedCable) => foldedCable.parent.parentMultiId.isEmpty)
        .toList();
  }

  static List<CableModel> flattened(Iterable<CableFamily> families) {
    return families
        .map((family) => [family.parent, ...family.children])
        .flattened
        .toList();
  }

  @override
  String toString() {
    return 'CableFamily(cable: ${parent.uid}, children: ${children.map((child) => child.uid)} )';
  }
}
