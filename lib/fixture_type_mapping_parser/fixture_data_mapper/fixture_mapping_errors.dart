abstract class FixtureMappingError {}

class NoMatchingFixtureInDatabaseError extends FixtureMappingError {
  final String providedName;

  NoMatchingFixtureInDatabaseError({required this.providedName});
}

class UnableToMatchFixtureNameError extends FixtureMappingError {
  final String providedName;

  UnableToMatchFixtureNameError({required this.providedName});
}

abstract class MultipleMatchError extends FixtureMappingError {
  final String sourceValue;
  final List<MatcherDetails> matcher;

  MultipleMatchError({
    required this.sourceValue,
    required this.matcher,
  });
}

class MultipleFixtureTypeMatchError extends MultipleMatchError {
  MultipleFixtureTypeMatchError(
      {required super.sourceValue, required super.matcher});
}

class MultipleFixtureModeMatchError extends MultipleMatchError {
  MultipleFixtureModeMatchError(
      {required super.sourceValue, required super.matcher});
}

class MatcherDetails {
  final String name;
  final List<String> patterns;

  MatcherDetails({
    required this.name,
    required this.patterns,
  });

  String toMessageXMLElement() {
    return '''
      <Fixture name="$name">
          \t${patterns.map((pattern) => '<Match pattern="$pattern"/>').join("\n")}
      </Fixture>
    ''';
  }
}
