// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/redux/models/fixture_type_model.dart';

class IntermediateFixtureModel {
  final FixtureTypeModel type;
  final String locationId;
  final int sequence;
  final String ephemeralId;

  IntermediateFixtureModel({
    required this.type,
    required this.locationId,
    required this.sequence,
    required this.ephemeralId,
  });

  IntermediateFixtureModel copyWith({
    FixtureTypeModel? type,
    String? ephemeralId,
    String? locationId,
    int? sequence,
  }) {
    return IntermediateFixtureModel(
      type: type ?? this.type,
      locationId: locationId ?? this.locationId,
      sequence: sequence ?? this.sequence,
      ephemeralId: ephemeralId ?? this.ephemeralId,
    );
  }

  @override
  String toString() {
    return type.shortName;
  }
}
