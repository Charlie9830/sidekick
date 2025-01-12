class InputFormatError extends Error {
  final int rowNumber;
  final String message;

  InputFormatError({
    required this.message,
    required this.rowNumber,
  });
}
