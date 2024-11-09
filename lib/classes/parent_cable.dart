// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/models/cable_model.dart';

class ParentCable {
  final CableModel parent;
  final List<CableModel> children;

  ParentCable(this.parent, this.children);

  ParentCable copyWith({
    CableModel? parent,
    List<CableModel>? children,
  }) {
    return ParentCable(
      parent ?? this.parent,
      children ?? this.children,
    );
  }
}
