// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/model_collection/model_collection_member.dart';

/// A single physical truss stick imported from an MVR.
///
/// Each [TrussModel] represents one truss section; the boundary between two
/// adjacent collinear sticks is a "join" where cables must be broken.
class TrussModel implements ModelCollectionMember {
  @override
  final String uid;
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

  TrussModel({
    this.uid = '',
    this.mvrId = '',
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
  });

  TrussModel copyWith({
    String? uid,
    String? mvrId,
    String? name,
    String? classing,
    double? x,
    double? y,
    double? z,
    double? rotationX,
    double? rotationY,
    double? rotationZ,
    double? length,
    double? width,
    double? height,
  }) {
    return TrussModel(
      uid: uid ?? this.uid,
      mvrId: mvrId ?? this.mvrId,
      name: name ?? this.name,
      classing: classing ?? this.classing,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      rotationZ: rotationZ ?? this.rotationZ,
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
      'x': x,
      'y': y,
      'z': z,
      'rotationX': rotationX,
      'rotationY': rotationY,
      'rotationZ': rotationZ,
      'length': length,
      'width': width,
      'height': height,
    };
  }

  factory TrussModel.fromMap(Map<String, dynamic> map) {
    return TrussModel(
      uid: (map['uid'] ?? '') as String,
      mvrId: (map['mvrId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      classing: (map['classing'] ?? '') as String,
      x: (map['x'] ?? 0).toDouble(),
      y: (map['y'] ?? 0).toDouble(),
      z: (map['z'] ?? 0).toDouble(),
      rotationX: (map['rotationX'] ?? 0).toDouble(),
      rotationY: (map['rotationY'] ?? 0).toDouble(),
      rotationZ: (map['rotationZ'] ?? 0).toDouble(),
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
