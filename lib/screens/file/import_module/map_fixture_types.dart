import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/data_lookup_result.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/fixture_data_mapper.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/fixture_mapping_errors.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_type_mapping_parser.dart';
import 'package:sidekick/screens/file/import_module/raw_fixture_model.dart';

/// Returns a Map of [FixtureMappingModel]'s keyed by a Union of their Source Fixture Type and Source Fixture mode data.
Map<String, FixtureMappingModel> mapFixtureTypes(
    {required List<RawFixtureModel> rawFixtures,
    required List<FixtureMatchModel> fixtureMatchers,
    required MappingFlavour flavour}) {
  final mapper =
      FixtureDataMapper(fixtureMatchers: fixtureMatchers, flavour: flavour);

  final typeAndModeUnions = rawFixtures.map((fixture) =>
      FixtureTypeAndModeUnion(fixture.fixtureType, fixture.fixtureMode));

  final mappings = typeAndModeUnions.map((union) {
    final sourceType = union.type;
    final sourceMode = union.mode;
    final lookupResult = mapper.lookupData(sourceType, sourceMode);

    if (lookupResult.fixture == const DataLookupResult.noResult()) {
      // No Result Found. We can't Drill down further without a concrete Fixture Type mapping.
      return FixtureMappingModel(
        sourceFixtureType: sourceType,
        sourceFixtureMode: sourceMode,
        typeMappingError: NoResultMappingError(),
      );
    }

    if (lookupResult.fixture.errors.isNotEmpty) {
      // Multiple Matchers were excited by this value, that suggests that the Matchers need to be more specific.
      return FixtureMappingModel(
        sourceFixtureType: sourceType,
        sourceFixtureMode: sourceMode,
        typeMappingError: MultipleMatchesMappingError(
            lookupResult.fixture.errors, MatchType.fixture),
      );
    }

    if (lookupResult.fixture.value.isEmpty) {
      // Multiple Matchers were excited by this value, that suggests that the Matchers need to be more specific.
      return FixtureMappingModel(
        sourceFixtureType: sourceType,
        sourceFixtureMode: sourceMode,
        typeMappingError: BlankValueMappingError(),
      );
    }


    // if (sourceType == "Clay Paky@Sharpy") {
    //   print("Stop");
    // }

    // By now we have a concrete Type value. So now we can drill down for the mode value.
    if (lookupResult.mode == const DataLookupResult.noResult()) {
      // No Mode Result found.
      return FixtureMappingModel(
        sourceFixtureType: sourceType,
        sourceFixtureMode: sourceMode,
        mappedFixtureType: lookupResult.fixture.value,
        modeMappingError: NoResultMappingError(),
      );
    }

    if (lookupResult.mode.errors.isNotEmpty) {
      // Multiple Matchers were excited by this value, that suggests that the Matchers need to be more specific.
      return FixtureMappingModel(
        sourceFixtureType: sourceType,
        sourceFixtureMode: sourceMode,
        mappedFixtureType: lookupResult.fixture.value,
        modeMappingError: MultipleMatchesMappingError(
          lookupResult.mode.errors,
          MatchType.mode,
        ),
      );
    }

    if (lookupResult.mode.value.isEmpty) {
      // Multiple Matchers were excited by this value, that suggests that the Matchers need to be more specific.
      return FixtureMappingModel(
        sourceFixtureType: sourceType,
        sourceFixtureMode: sourceMode,
        mappedFixtureType: lookupResult.fixture.value,
        modeMappingError: BlankValueMappingError(),
      );
    }

    // Made it this far so we should have a good value.
    return FixtureMappingModel(
      sourceFixtureType: sourceType,
      sourceFixtureMode: sourceMode,
      mappedFixtureType: lookupResult.fixture.value,
      mappedFixtureMode: lookupResult.mode.value,
    );
  });

  return Map<String, FixtureMappingModel>.fromEntries(
      mappings.map((mapping) => MapEntry(mapping.sourceKey, mapping)));
}

class FixtureTypeAndModeUnion {
  final String type;
  final String mode;

  FixtureTypeAndModeUnion(this.type, this.mode);
}

class FixtureMappingModel {
  final String sourceFixtureType;
  final String sourceFixtureMode;
  final String mappedFixtureType;
  final String mappedFixtureMode;
  final MappingError? typeMappingError;
  final MappingError? modeMappingError;

  FixtureMappingModel({
    required this.sourceFixtureType,
    required this.sourceFixtureMode,
    this.mappedFixtureMode = '',
    this.mappedFixtureType = '',
    this.typeMappingError,
    this.modeMappingError,
  });

  String get sourceKey => getSourceKey(sourceFixtureType, sourceFixtureMode);

  static String getSourceKey(
          String sourceFixtureType, String sourceFixtureMode) =>
      '$sourceFixtureType-$sourceFixtureMode';
}

abstract class MappingError {}

class NoResultMappingError extends MappingError {}

enum MatchType {
  fixture,
  mode,
}

class MultipleMatchesMappingError extends MappingError {
  late String message;
  MultipleMatchesMappingError(
      List<MultipleMatchError> errors, MatchType matchType) {
    final matchTypeString = switch (matchType) {
      MatchType.fixture => "<Fixture/>",
      MatchType.mode => "<Mode/>"
    };

    message =
        'The following $matchTypeString <Match/> elements were simultaneously triggered by the source value.'
        'This indicates that one or many of these Match elements needs to be more specific.'
        '\n'
        '${errors.expand((error) => error.matcher).map((matcher) => matcher.toMessageXMLElement()).join('\n')}';
  }
}

class BlankValueMappingError extends MappingError {
  final String message;

  BlankValueMappingError()
      : message =
            "You cannot map fixture type or fixture mode data to blank values."
                "Ensure the <Fixture name="
                "/> or <Mode name="
                "/> values are provided within the Fixture mapping file";
}
