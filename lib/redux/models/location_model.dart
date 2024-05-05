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
      RegExp('red', caseSensitive: false): 'R',
      RegExp('white', caseSensitive: false): 'W',
      RegExp('blue', caseSensitive: false): 'B',
      RegExp('green', caseSensitive: false): 'G',
      RegExp('brown', caseSensitive: false): 'BRN',
      RegExp('purple', caseSensitive: false): 'P',
      RegExp('LX1', caseSensitive: false): 'LX1',
      RegExp('LX2', caseSensitive: false): 'LX2',
      RegExp('LX3', caseSensitive: false): 'LX3',
      RegExp('LX4', caseSensitive: false): 'LX4',
      RegExp('LX5', caseSensitive: false): 'LX5',
      RegExp('LX6', caseSensitive: false): 'LX6',
      RegExp('A ', caseSensitive: false): 'A',
      RegExp('B ', caseSensitive: false): 'B',
      RegExp('C ', caseSensitive: false): 'C',
      RegExp('D ', caseSensitive: false): 'D',
      RegExp('SR ', caseSensitive: false): 'SR',
      RegExp('SL ', caseSensitive: false): 'SL',
    };

    final key =
        lookup.keys.firstWhereOrNull((regex) => regex.hasMatch(locationName));

    if (key == null) {
      return '';
    }

    return lookup[key]!;
  }
}
