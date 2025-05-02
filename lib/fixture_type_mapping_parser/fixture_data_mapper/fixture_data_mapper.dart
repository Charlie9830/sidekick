import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/compiled_fixture_predicate.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/compiled_mode_predicate.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/data_lookup_result.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/fixture_lookup_result.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/fixture_mapping_errors.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_type_mapping_parser.dart';

class FixtureDataMapper {
  final List<CompiledFixturePredicate> fixtureMatchPredicates;
  final MappingFlavour flavour;

  FixtureDataMapper(
      {required List<FixtureMatchModel> fixtureMatchers, required this.flavour})
      : fixtureMatchPredicates = _compilePredicates(fixtureMatchers, flavour);

  static List<CompiledFixturePredicate> _compilePredicates(
      List<FixtureMatchModel> fixtureMatchers, MappingFlavour console) {
    final predicates = fixtureMatchers.map((matcher) {
      final (positiveExps, negativeExps) =
          _mapPredicatesToExp(matcher.fixturePattern, console);

      return CompiledFixturePredicate(
        name: matcher.name,
        positiveExps: positiveExps,
        negativeExps: negativeExps,
        modePredicates: matcher.modePatterns.map(
          (modeMatcher) {
            final (positiveModeExps, negativeModeExps) =
                _mapPredicatesToExp(modeMatcher.patterns, console);

            return CompiledModePredicate(
              name: modeMatcher.name,
              positiveExps: positiveModeExps,
              negativeExps: negativeModeExps,
            );
          },
        ).toList(),
      );
    }).toList();
    return predicates;
  }

  static (List<RegExp>, List<RegExp>) _mapPredicatesToExp(
      MatchPatternModel predicates, MappingFlavour console) {
    // Callback to instantiate String patterns into RegExp objects.
    List<RegExp> mapToRegex(List<String> patterns) =>
        patterns.map((pattern) => RegExp(pattern)).toList();

    return switch (console) {
      MappingFlavour.ma2 => (
          mapToRegex(predicates.ma2.positive),
          mapToRegex(predicates.ma2.negative)
        ),
      MappingFlavour.mvr => (
          mapToRegex(predicates.mvr.positive),
          mapToRegex(predicates.mvr.negative),
        ),
    };
  }

  FixtureLookupResult lookupData(
      String fixtureNameSource, String fixtureModeSource) {
    final fixtureMatchResults = fixtureMatchPredicates
        .where((predicate) => predicate.hasFixtureMatch(fixtureNameSource))
        .toList();

    if (fixtureMatchResults.isEmpty) {
      return const FixtureLookupResult.noResult();
    }

    if (fixtureMatchResults.length > 1) {
      // Matcher predicate has generated a match for more than 1 source data string. This indicates that the Fixture
      // dictionary is not specific enough for this particular match element. Generate an error and attach it to the value.
      return FixtureLookupResult(
        fixture: DataLookupResult(value: "", errors: [
          MultipleFixtureTypeMatchError(
            sourceValue: fixtureNameSource,
            matcher: fixtureMatchResults
                .map((match) => MatcherDetails(
                    name: match.name,
                    patterns: match.positiveExps
                        .map((item) => item.pattern)
                        .toList()))
                .toList(),
          )
        ]),
        mode: const DataLookupResult
            .noResult(), // Without a concrete Fixture Result, we cannot reliably lookup mode information.
      );
    }

    final fixtureResult =
        DataLookupResult(value: fixtureMatchResults.first.name);
    return FixtureLookupResult(
        fixture: fixtureResult,

        // Drill down to match to a mode.
        mode: matchFixtureMode(
            fixtureModeSource, fixtureMatchResults.first.modePredicates));
  }

  DataLookupResult matchFixtureMode(
      String source, List<CompiledModePredicate> modePredicates) {
    final modeMatchResults = modePredicates
        .where((predicate) => predicate.hasModeMatch(source))
        .toList();

    if (modeMatchResults.isEmpty) {
      return const DataLookupResult.noResult();
    }

    if (modeMatchResults.length > 1) {
      // Matcher predicate has generated a match for more than 1 source data string. This indicates that the Fixture
      // dictionary is not specific enough for this particular match element. Generate an error and attach it to the value.
      return DataLookupResult(value: "", errors: [
        MultipleFixtureModeMatchError(
          sourceValue: source,
          matcher: modeMatchResults
              .map((match) => MatcherDetails(
                  name: match.name,
                  patterns:
                      match.positiveExps.map((item) => item.pattern).toList()))
              .toList(),
        )
      ]);
    }

    final name = modeMatchResults.first.name;
    return DataLookupResult(value: name);
  }
}
