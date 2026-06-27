class RawTrussModel {
  final String mvrId;
  final double x;
  final double y;
  final double z;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double length;
  final double width;
  final double height;

  RawTrussModel({
    required this.mvrId,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
    this.length = 0,
    this.width = 0,
    this.height = 0,
  });

  @override
  String toString() {
    return 'Truss: ($length, $width, $height)';
  }
}
