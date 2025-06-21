import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
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

  CableFamily.singleParent(
    this.parent,
  ) : children = const [];

  /// Will return a list of [CableFamily] where relevant child cables are folded into their parent cables.
  /// Children that have been folded will not appear in the top level collection.
  /// Note Children may appear as Parents if their actual parent has not been provided in the [cables] iterable.
  static List<CableFamily> createFamilies(Iterable<CableModel> cables) {
    final cableMap = cables.toModelMap();

    return cableMap.values.map((cable) {
      if (cable.isMultiCable) {
        return CableFamily(
            cable,
            cableMap.values
                .where((cable) => cable.parentMultiId == cable.uid)
                .toList());
      }

      return CableFamily(cable, []);
    }).toList();
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
