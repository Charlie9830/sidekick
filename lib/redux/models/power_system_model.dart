import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/named_color_model.dart';

class PowerSystemModel extends ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final NamedColorModel color;

  PowerSystemModel({
    required this.uid,
    this.name = '',
    this.color = NamedColors.none,
  });
}
