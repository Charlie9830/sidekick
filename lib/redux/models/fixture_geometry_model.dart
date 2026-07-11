// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';

/// One physical part of a fixture's GDTF geometry (base, yoke, head, ...),
/// reduced to the eight corners of its oriented box.
///
/// Corners are fixture-local (mm, Z-up, right-handed) with the origin at the
/// centre of the fixture's base, and stay oriented with the part. Keeping the
/// full 3D corners (rather than a pre-projected outline) lets any orthogonal
/// view — plan, front, side — be derived at paint time.
class GeometryPartModel {
  final String name;

  /// The GDTF `PrimitiveType` name of the part's model, e.g. 'Cylinder'.
  final String primitiveType;

  /// The eight corners of the part's box in fixture-local space (mm).
  final List<Vector3> corners;

  const GeometryPartModel({
    this.name = '',
    this.primitiveType = '',
    this.corners = const [],
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'primitiveType': primitiveType,
      'corners': corners.map((corner) => corner.toMap()).toList(),
    };
  }

  factory GeometryPartModel.fromMap(Map<String, dynamic> map) {
    return GeometryPartModel(
      name: (map['name'] ?? '') as String,
      primitiveType: (map['primitiveType'] ?? '') as String,
      corners: [
        for (final corner in (map['corners'] ?? []) as List<dynamic>)
          if (corner is Map<String, dynamic>) Vector3.fromMap(corner),
      ],
    );
  }
}

/// The physical geometry of one fixture type, imported from its GDTF file.
///
/// Keyed by the owning [FixtureTypeModel]'s uid so views can look the geometry
/// up straight from a fixture's `typeId`. To place a part in world space,
/// rotate the fixture-local corners by the fixture's rotation and translate by
/// its x/y/z.
class FixtureGeometryModel implements ModelCollectionMember {
  @override
  final String uid;

  /// The GDTF fixture type name the geometry was read from (informational).
  final String gdtfName;

  final List<GeometryPartModel> parts;

  /// Fixture-local axis-aligned bounds enclosing [parts] (mm).
  final Vector3 boundingBoxMin;
  final Vector3 boundingBoxMax;

  const FixtureGeometryModel({
    this.uid = '',
    this.gdtfName = '',
    this.parts = const [],
    this.boundingBoxMin = Vector3.zero,
    this.boundingBoxMax = Vector3.zero,
  });

  FixtureGeometryModel copyWith({
    String? uid,
    String? gdtfName,
    List<GeometryPartModel>? parts,
    Vector3? boundingBoxMin,
    Vector3? boundingBoxMax,
  }) {
    return FixtureGeometryModel(
      uid: uid ?? this.uid,
      gdtfName: gdtfName ?? this.gdtfName,
      parts: parts ?? this.parts,
      boundingBoxMin: boundingBoxMin ?? this.boundingBoxMin,
      boundingBoxMax: boundingBoxMax ?? this.boundingBoxMax,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'gdtfName': gdtfName,
      'parts': parts.map((part) => part.toMap()).toList(),
      'boundingBoxMin': boundingBoxMin.toMap(),
      'boundingBoxMax': boundingBoxMax.toMap(),
    };
  }

  factory FixtureGeometryModel.fromMap(Map<String, dynamic> map) {
    Vector3 corner(String key) {
      final value = map[key];
      return value is Map<String, dynamic>
          ? Vector3.fromMap(value)
          : Vector3.zero;
    }

    return FixtureGeometryModel(
      uid: (map['uid'] ?? '') as String,
      gdtfName: (map['gdtfName'] ?? '') as String,
      parts: [
        for (final part in (map['parts'] ?? []) as List<dynamic>)
          if (part is Map<String, dynamic>) GeometryPartModel.fromMap(part),
      ],
      boundingBoxMin: corner('boundingBoxMin'),
      boundingBoxMax: corner('boundingBoxMax'),
    );
  }

  String toJson() => json.encode(toMap());

  factory FixtureGeometryModel.fromJson(String source) =>
      FixtureGeometryModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'FixtureGeometryModel($gdtfName, ${parts.length} parts)';
}
