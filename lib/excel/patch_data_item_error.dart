enum PatchDataErrorLevel {
  warning,
  critical,
}

abstract class PatchDataItemError {
  final PatchDataErrorLevel level;

  PatchDataItemError()
      : level = PatchDataErrorLevel
            .critical; // Assumes a Critical error level if none is provided.

  PatchDataItemError.withLevel(this.level);
}

class NoRowDataError extends PatchDataItemError {
  NoRowDataError();
}

class MalformedRowError extends PatchDataItemError {
  MalformedRowError();
}

class MissingDataError extends PatchDataItemError {
  final String columnName;

  MissingDataError({
    required this.columnName,
  });
}

class InvalidDataTypeError extends PatchDataItemError {
  final String columnName;
  final Object data;
  final Type expectedType;

  InvalidDataTypeError({
    required this.columnName,
    required this.data,
    required this.expectedType,
  });
}

class DataFormatError extends PatchDataItemError {
  final String columnName;
  final Object data;

  DataFormatError({
    required this.columnName,
    required this.data,
  });
}

class NoMatchingFixtureTypeError extends PatchDataItemError {
  final String originalFixtureValue;

  NoMatchingFixtureTypeError(this.originalFixtureValue);
}

class NoMatchingLocationError extends PatchDataItemError {
  final String originalLocationValue;

  NoMatchingLocationError(this.originalLocationValue);
}
