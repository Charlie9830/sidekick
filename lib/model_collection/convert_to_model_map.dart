import 'package:sidekick/model_collection/model_collection_member.dart';

Map<String, T> convertToModelMap<T extends ModelCollectionMember>(
    Iterable<T> members) {
  return Map<String, T>.fromEntries(
      members.map((member) => MapEntry(member.uid, member)));
}

MapEntry<String, T> convertToMapEntry<T extends ModelCollectionMember>(
    T member) {
  return MapEntry<String, T>(member.uid, member);
}
