import 'dart:convert';
import 'dart:math' as math;

/// An immutable point or direction in world space.
///
/// All coordinates are in millimetres and follow the same right-handed, Z-up
/// convention as the imported MVR data, so a [Vector3] can hold either a truss
/// centroid, a fixture position, or a unit basis axis.
class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  static const zero = Vector3(0, 0, 0);
  static const unitX = Vector3(1, 0, 0);
  static const unitY = Vector3(0, 1, 0);
  static const unitZ = Vector3(0, 0, 1);

  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);

  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);

  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);

  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  Vector3 cross(Vector3 other) => Vector3(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x,
      );

  double get length => math.sqrt(x * x + y * y + z * z);

  double distanceTo(Vector3 other) => (this - other).length;

  /// This vector scaled to unit length.
  ///
  /// Returns [unitX] for a zero-length vector so that callers building an
  /// orthonormal basis always get a usable axis rather than NaNs.
  Vector3 get normalized {
    final magnitude = length;
    if (magnitude == 0) return unitX;
    return this * (1 / magnitude);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{'x': x, 'y': y, 'z': z};

  factory Vector3.fromMap(Map<String, dynamic> map) => Vector3(
        (map['x'] ?? 0).toDouble(),
        (map['y'] ?? 0).toDouble(),
        (map['z'] ?? 0).toDouble(),
      );

  String toJson() => json.encode(toMap());

  factory Vector3.fromJson(String source) =>
      Vector3.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      other is Vector3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vector3($x, $y, $z)';
}
