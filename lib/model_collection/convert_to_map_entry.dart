import 'package:sidekick/model_collection/model_collection_member.dart';

MapEntry<String, T> convertToMapEntry<T extends ModelCollectionMember>(
    T member) {
  return MapEntry<String, T>(member.uid, member);
}
