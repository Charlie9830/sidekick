import 'package:sidekick/excel/new/raw_row_data.dart';
import 'package:sidekick/excel/patch_data_item_error.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/import_settings_model.dart';

class ImportManagerViewModel {
  final String importFilePath;
  final ImportSettingsModel settings;
  final List<String> sheetNames;
  final List<RawRowViewModel> incomingRowVms;
  final List<RowPairViewModel> rowPairings;
  final void Function() onRefreshButtonPressed;
  final void Function(String selectedItem) onRowSelectionChanged;
  final String selectedRow;
  final List<PatchDataItemError> rowErrors;
  final int step;
  final void Function()? onNextButtonPressed;
  final void Function(String path) onFixtureDatabaseFilePathChanged;
  final void Function(String path) onFixtureMappingFilePathChanged;
  final String fixtureDatabaseFilePath;
  final String fixtureMappingFilePath;

  ImportManagerViewModel({
    required this.importFilePath,
    required this.settings,
    required this.sheetNames,
    required this.rowPairings,
    required this.onRefreshButtonPressed,
    required this.onRowSelectionChanged,
    required this.selectedRow,
    required this.rowErrors,
    required this.step,
    required this.onNextButtonPressed,
    required this.incomingRowVms,
    required this.onFixtureDatabaseFilePathChanged,
    required this.onFixtureMappingFilePathChanged,
    required this.fixtureDatabaseFilePath,
    required this.fixtureMappingFilePath,
  });
}

class RawRowViewModel {
  final RawRowData row;
  final String selectionId;

  RawRowViewModel({
    required this.row,
    required this.selectionId,
  });
}

class RowPairViewModel {
  final RawRowData? incoming;
  final FixtureViewModel? existing;
  final String selectionId;

  RowPairViewModel({
    required this.incoming,
    required this.existing,
    required this.selectionId,
  });

  bool get hasBoth => incoming != null && existing != null;
}

class FixtureViewModel {
  final FixtureModel existingFixture;
  final String locationName;
  final String fixtureTypeName;

  FixtureViewModel({
    required this.existingFixture,
    required this.locationName,
    required this.fixtureTypeName,
  });
}
