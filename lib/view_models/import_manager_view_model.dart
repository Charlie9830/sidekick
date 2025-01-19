import 'package:sidekick/excel/new/raw_row_data.dart';
import 'package:sidekick/excel/patch_data_item_error.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/import_settings_model.dart';

class ImportManagerViewModel {
  final String importFilePath;
  final ImportSettingsModel settings;
  final List<String> sheetNames;
  final List<RowPairViewModel> rowPairings;
  final void Function() onRefreshButtonPressed;
  final void Function(String selectedItem) onRowSelectionChanged;
  final String selectedRow;
  final List<PatchDataItemError> rowErrors;

  ImportManagerViewModel({
    required this.importFilePath,
    required this.settings,
    required this.sheetNames,
    required this.rowPairings,
    required this.onRefreshButtonPressed,
    required this.onRowSelectionChanged,
    required this.selectedRow,
    required this.rowErrors,
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
}

class FixtureViewModel {
  final FixtureModel fixture;
  final String locationName;
  final String fixtureTypeName;

  FixtureViewModel({
    required this.fixture,
    required this.locationName,
    required this.fixtureTypeName,
  });
}
