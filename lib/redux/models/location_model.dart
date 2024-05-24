import 'dart:convert';
import 'dart:ui';

import 'package:collection/collection.dart';

class LocationModel {
  final String uid;
  final String name;
  final Color color;
  final String multiPrefix;

  static const Color noColor = Color.fromARGB(0, 0, 0, 0);

  LocationModel({
    required this.uid,
    this.name = '',
    required this.color,
    this.multiPrefix = '',
  });

  const LocationModel.none()
      : uid = 'none',
        name = '',
        multiPrefix = '',
        color = LocationModel.noColor;

  LocationModel copyWith({
    String? uid,
    String? name,
    Color? color,
    String? multiPrefix,
  }) {
    return LocationModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      color: color ?? this.color,
      multiPrefix: multiPrefix ?? this.multiPrefix,
    );
  }

  String getPrefixedDataPatch(int universe, int patchNumber,
      {String? parentMultiName}) {
    if (this == const LocationModel.none()) {
      return 'No Location';
    }

    if (parentMultiName != null) {
      return '$parentMultiName.$patchNumber U$universe';
    } else {
      return '$multiPrefix$patchNumber U$universe';
    }
  }

  String getPrefixedDataMultiPatch(int patchNumber) {
    if (this == const LocationModel.none()) {
      return 'No Location';
    }

    return '$multiPrefix$patchNumber';
  }

  String getPrefixedPowerMulti(int multiOutlet) {
    if (this == const LocationModel.none()) {
      return 'No Multi';
    }
    return '$multiPrefix$multiOutlet';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'color': color.value,
      'multiPrefix': multiPrefix,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      color: Color(map['color']),
      multiPrefix: map['multiPrefix'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationModel.fromJson(String source) =>
      LocationModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LocationModel(uid: $uid, name: $name, color: $color, multiPrefix: $multiPrefix)';
  }

  static Color matchColor(String locationName) {
    final lookup = <RegExp, Color>{
      RegExp(r'red ', caseSensitive: false):
          const Color.fromARGB(255, 255, 0, 0),
      RegExp(r'white ', caseSensitive: false):
          const Color.fromARGB(255, 255, 255, 255),
      RegExp(r'blue ', caseSensitive: false):
          const Color.fromARGB(255, 0, 0, 255),
      RegExp(r'green ', caseSensitive: false):
          const Color.fromARGB(255, 0, 255, 0),
      RegExp(r'brown ', caseSensitive: false):
          const Color.fromARGB(255, 255, 145, 0),
      RegExp(r'SR ', caseSensitive: false):
          const Color.fromARGB(255, 255, 100, 0),
      RegExp(r'Stage Right ', caseSensitive: false):
          const Color.fromARGB(255, 255, 100, 0),
      RegExp(r'SL ', caseSensitive: false):
          const Color.fromARGB(255, 255, 255, 0),
      RegExp(r'Stage Left ', caseSensitive: false):
          const Color.fromARGB(255, 255, 255, 0),
      RegExp(r'DSL ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'DSC ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'DSR ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'MSL ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'MSC ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'MSR ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'USL ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'USC ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'USR ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'DS ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'MS ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
      RegExp(r'US ', caseSensitive: false):
          const Color.fromARGB(255, 128, 128, 128),
    };

    final key =
        lookup.keys.firstWhereOrNull((regex) => regex.hasMatch(locationName));

    if (key == null) {
      return LocationModel.noColor;
    }

    return lookup[key]!;
  }

  static String matchMultiPrefix(String locationName) {
    final lookup = <RegExp, String>{
      // Colors
      RegExp('red', caseSensitive: false): 'R',
      RegExp('white', caseSensitive: false): 'W',
      RegExp('blue', caseSensitive: false): 'B',
      RegExp('green', caseSensitive: false): 'G',
      RegExp('brown', caseSensitive: false): 'BRN',
      RegExp('purple', caseSensitive: false): 'P',

      // LX's
      RegExp('LX1', caseSensitive: false): 'LX1',
      RegExp('LX2', caseSensitive: false): 'LX2',
      RegExp('LX3', caseSensitive: false): 'LX3',
      RegExp('LX4', caseSensitive: false): 'LX4',
      RegExp('LX5', caseSensitive: false): 'LX5',
      RegExp('LX6', caseSensitive: false): 'LX6',
      RegExp('LX7', caseSensitive: false): 'LX7',
      RegExp('LX8', caseSensitive: false): 'LX8',

      // Directions
      RegExp('SR ', caseSensitive: false): 'SR',
      RegExp('SL ', caseSensitive: false): 'SL',

      // Alpha Numerics
      RegExp('A ', caseSensitive: false): 'A',
      RegExp('B ', caseSensitive: false): 'B',
      RegExp('C ', caseSensitive: false): 'C',
      RegExp('D ', caseSensitive: false): 'D',
      RegExp('E ', caseSensitive: false): 'E',
      RegExp('F ', caseSensitive: false): 'F',
      RegExp('G ', caseSensitive: false): 'G',
      RegExp('H ', caseSensitive: false): 'H',

      // Fingers
      RegExp('Finger.*1', caseSensitive: false): 'F1.',
      RegExp('Finger.*2', caseSensitive: false): 'F2.',
      RegExp('Finger.*3', caseSensitive: false): 'F3.',
      RegExp('Finger.*4', caseSensitive: false): 'F4.',
      RegExp('Finger.*5', caseSensitive: false): 'F5.',
      RegExp('Finger.*6', caseSensitive: false): 'F6.',
      RegExp('Finger.*7', caseSensitive: false): 'F7.',
      RegExp('Finger.*8', caseSensitive: false): 'F8.',
      RegExp('Finger.*9', caseSensitive: false): 'F9.',
      RegExp('Finger.*10', caseSensitive: false): 'F10.',
      RegExp('Finger.*11', caseSensitive: false): 'F11.',
      RegExp('Finger.*12', caseSensitive: false): 'F12.',
      RegExp('Finger.*13', caseSensitive: false): 'F13.',
      RegExp('Finger.*14', caseSensitive: false): 'F14.',
      RegExp('Finger.*15', caseSensitive: false): 'F15.',
      RegExp('Finger.*16', caseSensitive: false): 'F16.',

      // Numeric Verticals
      RegExp('Vert.*1', caseSensitive: false): 'V1.',
      RegExp('Vert.*2', caseSensitive: false): 'V2.',
      RegExp('Vert.*3', caseSensitive: false): 'V3.',
      RegExp('Vert.*4', caseSensitive: false): 'V4.',
      RegExp('Vert.*5', caseSensitive: false): 'V5.',
      RegExp('Vert.*6', caseSensitive: false): 'V6.',
      RegExp('Vert.*7', caseSensitive: false): 'V7.',
      RegExp('Vert.*8', caseSensitive: false): 'V8.',
      RegExp('Vert.*9', caseSensitive: false): 'V9.',
      RegExp('Vert.*10', caseSensitive: false): 'V10.',
      RegExp('Vert.*11', caseSensitive: false): 'V11.',
      RegExp('Vert.*12', caseSensitive: false): 'V12.',

      // Numeric Towers
      RegExp('Tower.*1', caseSensitive: false): 'T1.',
      RegExp('Tower.*2', caseSensitive: false): 'T2.',
      RegExp('Tower.*3', caseSensitive: false): 'T3.',
      RegExp('Tower.*4', caseSensitive: false): 'T4.',
      RegExp('Tower.*5', caseSensitive: false): 'T5.',
      RegExp('Tower.*6', caseSensitive: false): 'T6.',
      RegExp('Tower.*7', caseSensitive: false): 'T7.',
      RegExp('Tower.*8', caseSensitive: false): 'T8.',
      RegExp('Tower.*9', caseSensitive: false): 'T9.',
      RegExp('Tower.*10', caseSensitive: false): 'T10.',
      RegExp('Tower.*11', caseSensitive: false): 'T11.',
      RegExp('Tower.*12', caseSensitive: false): 'T12.',

      // Numeric Trusses
      RegExp('Truss.*1', caseSensitive: false): 'T1.',
      RegExp('Truss.*2', caseSensitive: false): 'T2.',
      RegExp('Truss.*3', caseSensitive: false): 'T3.',
      RegExp('Truss.*4', caseSensitive: false): 'T4.',
      RegExp('Truss.*5', caseSensitive: false): 'T5.',
      RegExp('Truss.*6', caseSensitive: false): 'T6.',
      RegExp('Truss.*7', caseSensitive: false): 'T7.',
      RegExp('Truss.*8', caseSensitive: false): 'T8.',
      RegExp('Truss.*9', caseSensitive: false): 'T9.',
      RegExp('Truss.*10', caseSensitive: false): 'T10.',
      RegExp('Truss.*11', caseSensitive: false): 'T11.',
      RegExp('Truss.*12', caseSensitive: false): 'T12.',
      RegExp('Truss.*13', caseSensitive: false): 'T13.',
      RegExp('Truss.*14', caseSensitive: false): 'T14.',
      RegExp('Truss.*15', caseSensitive: false): 'T15.',
      RegExp('Truss.*16', caseSensitive: false): 'T16.',
      RegExp('Truss.*17', caseSensitive: false): 'T17.',
      RegExp('Truss.*18', caseSensitive: false): 'T18.',
      RegExp('Truss.*19', caseSensitive: false): 'T19.',
      RegExp('Truss.*20', caseSensitive: false): 'T20.',
      RegExp('Truss.*21', caseSensitive: false): 'T21.',
      RegExp('Truss.*22', caseSensitive: false): 'T22.',
      RegExp('Truss.*23', caseSensitive: false): 'T23.',
      RegExp('Truss.*24', caseSensitive: false): 'T24.',
    };

    final key =
        lookup.keys.firstWhereOrNull((regex) => regex.hasMatch(locationName));

    if (key == null) {
      return '';
    }

    return lookup[key]!;
  }
}
