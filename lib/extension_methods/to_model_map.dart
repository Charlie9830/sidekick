import 'package:sidekick/model_collection/model_collection_member.dart';

extension ToModelMap<T extends ModelCollectionMember> on Iterable<T> {
  Map<String, T> toModelMap() {
    return Map<String, T>.fromEntries(
        map((member) => MapEntry(member.uid, member)));
  }
}
