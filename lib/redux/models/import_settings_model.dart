enum ImportType {
  addNewRecords,
  onlyUpdateExisting,
}

class ImportSettingsModel {
  final bool mergeWithExisting;
  final bool overwriteSeqNumber;
  final bool overwriteType;
  final bool overwriteLocation;
  final bool overwriteAddress;
  final ImportType type;
  final String patchDataSourceSheetName;

  const ImportSettingsModel({
    this.mergeWithExisting = false,
    this.overwriteAddress = false,
    this.overwriteLocation = false,
    this.overwriteSeqNumber = false,
    this.overwriteType = false,
    this.type = ImportType.addNewRecords,
    this.patchDataSourceSheetName = 'Sheet1',
  });

  ImportSettingsModel copyWith({
    bool? mergeWithExisting,
    bool? overwriteSeqNumber,
    bool? overwriteType,
    bool? overwriteLocation,
    bool? overwriteAddress,
    ImportType? type,
    String? patchDataSourceSheetName,
  }) {
    return ImportSettingsModel(
      mergeWithExisting: mergeWithExisting ?? this.mergeWithExisting,
      overwriteSeqNumber: overwriteSeqNumber ?? this.overwriteSeqNumber,
      overwriteType: overwriteType ?? this.overwriteType,
      overwriteLocation: overwriteLocation ?? this.overwriteLocation,
      overwriteAddress: overwriteAddress ?? this.overwriteAddress,
      type: type ?? this.type,
      patchDataSourceSheetName:
          patchDataSourceSheetName ?? this.patchDataSourceSheetName,
    );
  }
}
