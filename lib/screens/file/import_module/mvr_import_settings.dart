enum MvrLocationDataSource {
  layers,
  classes,
  position,
  grouping,
}

class MvrImportSettings {
  final MvrLocationDataSource locationDataSource;

  MvrImportSettings({
    required this.locationDataSource,
  });

  MvrImportSettings copyWith({
    MvrLocationDataSource? locationDataSource,
  }) {
    return MvrImportSettings(
      locationDataSource: locationDataSource ?? this.locationDataSource,
    );
  }
}
