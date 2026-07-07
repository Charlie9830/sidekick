import 'package:sidekick/cable_graph/vector3.dart';

/// A truss as read from an MVR, before it is mapped into a [TrussModel].
///
/// Geometry is already expressed in the same world frame and units (mm, Z-up)
/// as the imported fixtures, so no scaling or re-anchoring happens downstream.
class RawTrussModel {
  final String mvrId;
  final String name;
  final String classing;

  /// World-space centroid of the truss geometry (mm).
  final Vector3 center;

  /// Unit world directions of the truss's local length, width and height axes.
  final Vector3 lengthAxis;
  final Vector3 widthAxis;
  final Vector3 heightAxis;

  /// Physical dimensions of the truss in its own local frame (mm).
  final double length;
  final double width;
  final double height;

  RawTrussModel({
    required this.mvrId,
    this.name = '',
    this.classing = '',
    this.center = Vector3.zero,
    this.lengthAxis = Vector3.unitX,
    this.widthAxis = Vector3.unitY,
    this.heightAxis = Vector3.unitZ,
    this.length = 0,
    this.width = 0,
    this.height = 0,
  });

  @override
  String toString() => 'Truss: ($length, $width, $height)';
}
