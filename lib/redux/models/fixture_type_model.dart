import 'package:sidekick/model_collection/model_collection_member.dart';

class FixtureTypeModel extends ModelCollectionMember {
  @override
  final String uid;
  final String originalMake;
  final String originalModel;
  final String name;
  final String shortName;
  final double amps;
  final int maxPiggybacks;

  FixtureTypeModel({
    required this.uid,
    this.originalMake = '',
    this.originalModel = '',
    this.name = '',
    this.shortName = '',
    this.amps = 0.0,
    this.maxPiggybacks = 1,
  });

  const FixtureTypeModel.blank()
      : uid = "",
        name = "",
        shortName = "",
        originalMake = '',
        originalModel = '',
        amps = 0,
        maxPiggybacks = 1;

  bool get canPiggyback => maxPiggybacks != 1;

  FixtureTypeModel copyWith({
    String? uid,
    String? originalMake,
    String? originalModel,
    String? name,
    String? shortName,
    double? amps,
    int? maxPiggybacks,
  }) {
    return FixtureTypeModel(
      uid: uid ?? this.uid,
      originalMake: originalMake ?? this.originalMake,
      originalModel: originalModel ?? this.originalModel,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      amps: amps ?? this.amps,
      maxPiggybacks: maxPiggybacks ?? this.maxPiggybacks,
    );
  }
}
