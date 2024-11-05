// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/models/cable_model.dart';

class CableAndChildrenTuple {
  final CableModel parent;
  final List<CableModel> children;

  CableAndChildrenTuple(this.parent, this.children);

  CableAndChildrenTuple copyWith({
    CableModel? parent,
    List<CableModel>? children,
  }) {
    return CableAndChildrenTuple(
      parent ?? this.parent,
      children ?? this.children,
    );
  }
}
