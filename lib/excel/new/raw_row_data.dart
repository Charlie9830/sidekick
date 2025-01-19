// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/excel/patch_data_item_error.dart';

class RawRowData {
  final int rowNumber;
  final String fid;
  final String fixtureType;
  final String fixtureMode;
  final String attachedFixtureTypeId;
  final String attachedLocationId;
  final String location;
  final int universe;
  final int address;
  final Set<PatchDataItemError> errors;

  RawRowData({
    required this.rowNumber,
    this.fid = '',
    this.fixtureType = '',
    this.attachedFixtureTypeId = '',
    this.fixtureMode = '',
    this.location = '',
    this.attachedLocationId = '',
    this.universe = 0,
    this.address = 0,
    this.errors = const {},
  });
  
  RawRowData copyWith({
    int? rowNumber,
    String? fid,
    String? fixtureType,
    String? fixtureMode,
    String? attachedFixtureTypeId,
    String? attachedLocationId,
    String? location,
    int? universe,
    int? address,
    Set<PatchDataItemError>? errors,
  }) {
    return RawRowData(
      rowNumber: rowNumber ?? this.rowNumber,
      fid: fid ?? this.fid,
      fixtureType: fixtureType ?? this.fixtureType,
      fixtureMode: fixtureMode ?? this.fixtureMode,
      attachedFixtureTypeId:
          attachedFixtureTypeId ?? this.attachedFixtureTypeId,
      attachedLocationId: attachedLocationId ?? this.attachedLocationId,
      location: location ?? this.location,
      universe: universe ?? this.universe,
      address: address ?? this.address,
      errors: errors ?? this.errors,
    );
  }

  RawRowData copyWithError(PatchDataItemError error) {
    return copyWith(errors: errors.toSet()..add(error));
  }
}
