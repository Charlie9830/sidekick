import 'package:sidekick/redux/models/export_error_model.dart';

class SetIsValidatingExportData {
  final bool value;

  SetIsValidatingExportData(this.value);
}

class SetExportErrors {
  final List<ExportErrorModel> errors;

  SetExportErrors(this.errors);
}

class SetOpenAfterExport {
  final bool value;

  SetOpenAfterExport(this.value);
}

class SetLastUsedExportDirectory {
  final String value;

  SetLastUsedExportDirectory(this.value);
}
