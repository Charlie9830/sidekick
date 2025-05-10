import 'package:sidekick/redux/models/location_model.dart';

class ExportViewModel {
  final Map<String, LocationModel> locations;
  final void Function() onExportButtonPressed;
  final String lastUsedExportDirectory;
  final void Function() onChooseExportDirectoryButtonPressed;
  final String projectName;
  final void Function(String newValue) onProjectNameChanged;
  final bool openAfterExport;
  final void Function(bool? newValue) onOpenAfterExportChanged;

  ExportViewModel({
    required this.locations,
    required this.onExportButtonPressed,
    required this.lastUsedExportDirectory,
    required this.projectName,
    required this.onChooseExportDirectoryButtonPressed,
    required this.onProjectNameChanged,
    required this.onOpenAfterExportChanged,
    required this.openAfterExport,
  });
}
