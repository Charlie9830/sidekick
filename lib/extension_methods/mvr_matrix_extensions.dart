import 'package:mvr/mvr.dart';

/// Splitting, combining and serializing [MVRMatrix] transforms.
extension MVRMatrixExtensions on MVRMatrix {
  /// This matrix with its translation zeroed, leaving only the rotation (and
  /// any scale) in its basis rows.
  MVRMatrix get rotationOnly => withTranslation(0, 0, 0);

  /// This matrix's basis rows with the translation replaced by ([x], [y],
  /// [z]).
  MVRMatrix withTranslation(double x, double y, double z) => MVRMatrix([
    for (final row in matrix.take(3)) [...row],
    [x, y, z],
  ]);

  /// Serializes the matrix as its four rows of three doubles.
  ///
  /// The rows are copied so the result never aliases this matrix's mutable
  /// lists.
  List<List<double>> toJson() => [
    for (final row in matrix) [...row],
  ];

  /// Parses a matrix serialized by [toJson], falling back to identity when
  /// [value] is missing or malformed so a bad entry cannot break file load.
  static MVRMatrix fromJson(Object? value) {
    if (value is! List || value.length != 4) {
      return const MVRMatrix.identity();
    }

    final rows = [
      for (final row in value)
        if (row is List && row.length == 3 && row.every((cell) => cell is num))
          [for (final cell in row) (cell as num).toDouble()],
    ];

    return rows.length == 4 ? MVRMatrix(rows) : const MVRMatrix.identity();
  }
}
