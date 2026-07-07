// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math' as math;

import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';

/// A single physical truss stick imported from an MVR.
///
/// Each [TrussModel] represents one truss section; the boundary between two
/// adjacent collinear sticks is a "join" where cables must be broken.
///
/// The stick is modelled as an oriented box: [center] is its world-space
/// centroid (mm) and [lengthAxis], [widthAxis] and [heightAxis] are the unit
/// world directions of its local length, width and height axes. Storing the
/// full basis (rather than a single Z rotation) lets the geometry engine handle
/// trusses raked or rolled about any axis, not just flat ones.
class TrussModel implements ModelCollectionMember {
  @override
  final String uid;
  final String mvrId;
  final String name;
  final String classing;

  /// World-space centroid of the stick (mm).
  final Vector3 center;

  /// Unit world direction of the stick's local length (long) axis.
  final Vector3 lengthAxis;

  /// Unit world direction of the stick's local width axis.
  final Vector3 widthAxis;

  /// Unit world direction of the stick's local height (up) axis.
  final Vector3 heightAxis;

  /// Physical dimensions of the stick in its own local frame (mm).
  final double length;
  final double width;
  final double height;

  TrussModel({
    this.uid = '',
    this.mvrId = '',
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

  /// World X of the centroid.
  double get x => center.x;

  /// World Y of the centroid.
  double get y => center.y;

  /// World Z of the centroid.
  double get z => center.z;

  /// The stick's orientation about the vertical (Z) axis, in degrees.
  ///
  /// Derived from the length axis for the top-down plan view. Trusses raked out
  /// of the horizontal plane also carry that information in [lengthAxis] /
  /// [heightAxis]; this getter only exposes the planar component.
  double get rotationZ =>
      math.atan2(lengthAxis.y, lengthAxis.x) * 180 / math.pi;

  TrussModel copyWith({
    String? uid,
    String? mvrId,
    String? name,
    String? classing,
    Vector3? center,
    Vector3? lengthAxis,
    Vector3? widthAxis,
    Vector3? heightAxis,
    double? length,
    double? width,
    double? height,
  }) {
    return TrussModel(
      uid: uid ?? this.uid,
      mvrId: mvrId ?? this.mvrId,
      name: name ?? this.name,
      classing: classing ?? this.classing,
      center: center ?? this.center,
      lengthAxis: lengthAxis ?? this.lengthAxis,
      widthAxis: widthAxis ?? this.widthAxis,
      heightAxis: heightAxis ?? this.heightAxis,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'mvrId': mvrId,
      'name': name,
      'classing': classing,
      'center': center.toMap(),
      'lengthAxis': lengthAxis.toMap(),
      'widthAxis': widthAxis.toMap(),
      'heightAxis': heightAxis.toMap(),
      'length': length,
      'width': width,
      'height': height,
    };
  }

  factory TrussModel.fromMap(Map<String, dynamic> map) {
    Vector3 axis(String key, Vector3 fallback) {
      final value = map[key];
      return value is Map<String, dynamic> ? Vector3.fromMap(value) : fallback;
    }

    final center = map['center'] is Map<String, dynamic>
        ? Vector3.fromMap(map['center'] as Map<String, dynamic>)
        : Vector3.zero;

    return TrussModel(
      uid: (map['uid'] ?? '') as String,
      mvrId: (map['mvrId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      classing: (map['classing'] ?? '') as String,
      center: center,
      lengthAxis: axis('lengthAxis', Vector3.unitX),
      widthAxis: axis('widthAxis', Vector3.unitY),
      heightAxis: axis('heightAxis', Vector3.unitZ),
      length: (map['length'] ?? 0).toDouble(),
      width: (map['width'] ?? 0).toDouble(),
      height: (map['height'] ?? 0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory TrussModel.fromJson(String source) =>
      TrussModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'TrussModel($name, $length x $width x $height)';
}
