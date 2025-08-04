import 'package:sidekick/model_collection/model_collection_member.dart';

abstract class Outlet extends ModelCollectionMember {
  @override
  final String uid;
  final String locationId;
  final int number;
  final String name;

  const Outlet({
    required this.uid,
    required this.locationId,
    required this.number,
    required this.name,
  });

  Outlet copyWith();
}


