import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/fixture_mapping_errors.dart';

class DataLookupResult {
  final String value;
  final List<MultipleMatchError> errors;

  const DataLookupResult({required this.value, this.errors = const []});

  const DataLookupResult.noResult()
      : value = "",
        errors = const [];
}
