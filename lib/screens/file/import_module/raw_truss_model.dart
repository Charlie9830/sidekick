class RawTrussModel {
  final String mvrId;
  final String name;
  final String classing;
  final double x;
  final double y;
  final double z;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double length;
  final double width;
  final double height;

  /// Offset of the geometry centre from the matrix origin, along the truss
  /// length, width and height axes (in the same units as [length]).
  final double offsetLength;
  final double offsetWidth;
  final double offsetHeight;

  RawTrussModel({
    required this.mvrId,
    this.name = '',
    this.classing = '',
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.offsetLength = 0,
    this.offsetWidth = 0,
    this.offsetHeight = 0,
  });

  @override
  String toString() {
    return 'Truss: ($length, $width, $height)';
  }
}
