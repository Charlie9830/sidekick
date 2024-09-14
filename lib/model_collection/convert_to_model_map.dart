import 'package:sidekick/model_collection/model_collection_member.dart';

Map<String, T> convertToModelMap<T extends ModelCollectionMember>(
    Iterable<T> members) {
  return Map<String, T>.fromEntries(
      members.map((member) => MapEntry(member.uid, member)));
}
