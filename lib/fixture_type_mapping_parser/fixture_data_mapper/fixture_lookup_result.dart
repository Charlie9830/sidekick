import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/data_lookup_result.dart';

class FixtureLookupResult {
  final DataLookupResult fixture;
  final DataLookupResult mode;

  FixtureLookupResult({
    required this.fixture,
    required this.mode,
  });

  const FixtureLookupResult.noResult()
      : fixture = const DataLookupResult(value: ""),
        mode = const DataLookupResult(value: '');
}
