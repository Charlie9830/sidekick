// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/screens/file/import_module/mvr_import_settings.dart';
import 'package:sidekick/screens/file/import_module/select_file_control.dart';

class PatchImportSettings {
  final PatchSource source;
  final MvrLocationDataSource mvrLocationDataSource;

  PatchImportSettings({
    required this.source,
    required this.mvrLocationDataSource,
  });

  PatchImportSettings copyWith({
    PatchSource? source,
    MvrLocationDataSource? mvrLocationDataSource,
  }) {
    return PatchImportSettings(
      source: source ?? this.source,
      mvrLocationDataSource:
          mvrLocationDataSource ?? this.mvrLocationDataSource,
    );
  }
}
