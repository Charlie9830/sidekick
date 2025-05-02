import 'package:sidekick/fixture_type_mapping_parser/fixture_data_mapper/compiled_mode_predicate.dart';

class CompiledFixturePredicate {
  final String name;
  final List<RegExp> positiveExps;
  final List<RegExp> negativeExps;
  final List<CompiledModePredicate> modePredicates;

  CompiledFixturePredicate({
    required this.name,
    required this.positiveExps,
    required this.negativeExps,
    required this.modePredicates,
  });

  bool hasFixtureMatch(String source) {
    return positiveExps.any((regex) => regex.hasMatch(source)) &&
        negativeExps.every((regex) => regex.hasMatch(source) == false);
  }
}
