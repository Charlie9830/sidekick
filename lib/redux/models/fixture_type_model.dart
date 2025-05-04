import 'package:sidekick/model_collection/model_collection_member.dart';

class FixtureTypeModel extends ModelCollectionMember {
  @override
  final String uid;
  final String make;
  final String model;
  final String name;
  final String shortName;
  final double amps;
  final int maxPiggybacks;

  FixtureTypeModel({
    required this.uid,
    this.make = '',
    this.model = '',
    this.name = '',
    this.shortName = '',
    this.amps = 0.0,
    this.maxPiggybacks = 1,
  });

  const FixtureTypeModel.blank()
      : uid = "",
        name = "",
        shortName = "",
        make = '',
        model = '',
        amps = 0,
        maxPiggybacks = 1;

  bool get canPiggyback => maxPiggybacks != 1;

  FixtureTypeModel copyWith({
    String? uid,
    String? make,
    String? model,
    String? name,
    String? shortName,
    double? amps,
    int? maxPiggybacks,
  }) {
    return FixtureTypeModel(
      uid: uid ?? this.uid,
      make: make ?? this.make,
      model: make ?? this.model,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      amps: amps ?? this.amps,
      maxPiggybacks: maxPiggybacks ?? this.maxPiggybacks,
    );
  }
}
