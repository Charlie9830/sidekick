// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/fixture_mapping_errors.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';

class RawFixtureModel {
  final String mvrId;
  final String mvrLayerId;
  final String mvrLocationId;
  final String generatedId;
  final int fixtureId;
  final String fixtureType;
  final String fixtureMode;
  final String locationName;
  final String fixtureIdString;
  final String associatedLocationId;
  final String associatedFixtureTypeId;
  final String sanitizedModeName;
  final DMXAddressModel address;
  final List<MultipleMatchError> modeMappingErrors;
  final List<FixtureMappingError> typeMappingErrors;
  final String generatedLocationId;

  RawFixtureModel({
    required this.fixtureId,
    required this.fixtureMode,
    required this.fixtureType,
    required this.locationName,
    required this.fixtureIdString,
    required this.generatedId,
    required this.mvrId,
    required this.mvrLayerId,
    required this.mvrLocationId,
    required this.address,
    this.associatedFixtureTypeId = '',
    this.associatedLocationId = '',
    this.sanitizedModeName = '',
    this.modeMappingErrors = const [],
    this.typeMappingErrors = const [],
    this.generatedLocationId = '',
  });

  RawFixtureModel copyWith({
    String? mvrId,
    String? mvrLayerId,
    String? mvrLocationId,
    String? generatedId,
    int? fixtureId,
    String? fixtureType,
    String? fixtureMode,
    String? locationName,
    String? fixtureIdString,
    String? associatedLocationId,
    String? associatedFixtureTypeId,
    String? sanitizedModeName,
    DMXAddressModel? address,
    List<MultipleMatchError>? modeMappingErrors,
    List<FixtureMappingError>? typeMappingErrors,
    String? generatedLocationId,
  }) {
    return RawFixtureModel(
      mvrId: mvrId ?? this.mvrId,
      mvrLayerId: mvrLayerId ?? this.mvrLayerId,
      mvrLocationId: mvrLocationId ?? this.mvrLocationId,
      generatedId: generatedId ?? this.generatedId,
      fixtureId: fixtureId ?? this.fixtureId,
      fixtureType: fixtureType ?? this.fixtureType,
      fixtureMode: fixtureMode ?? this.fixtureMode,
      locationName: locationName ?? this.locationName,
      fixtureIdString: fixtureIdString ?? this.fixtureIdString,
      associatedLocationId: associatedLocationId ?? this.associatedLocationId,
      associatedFixtureTypeId:
          associatedFixtureTypeId ?? this.associatedFixtureTypeId,
      sanitizedModeName: sanitizedModeName ?? this.sanitizedModeName,
      address: address ?? this.address,
      modeMappingErrors: modeMappingErrors ?? this.modeMappingErrors,
      typeMappingErrors: typeMappingErrors ?? this.typeMappingErrors,
      generatedLocationId: generatedLocationId ?? this.generatedLocationId,
    );
  }
}
