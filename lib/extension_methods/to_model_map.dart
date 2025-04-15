import 'package:sidekick/model_collection/convert_to_model_map.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';

extension ToModelMap<T extends ModelCollectionMember> on Iterable<T> {
  Map<String, T> toModelMap() {
    return convertToModelMap(this);
  }
}
