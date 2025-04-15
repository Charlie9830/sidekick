import 'dart:convert';
import 'dart:ui';

import 'package:collection/collection.dart';

import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/data_multi_model.dart';
import 'package:sidekick/redux/models/data_patch_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/named_color_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class LocationModel extends ModelCollectionMember with DiffComparable {
  @override
  final String uid;
  final String name;
  final LabelColorModel color;
  final String multiPrefix;
  final bool isPowerPatchLocked;
  final bool isDataPatchLocked;
  final String delimiter;
  final Set<String> hybridIds;

  static const Color noColor = Color.fromARGB(0, 0, 0, 0);

  LocationModel(
      {required this.uid,
      this.name = '',
      required this.color,
      this.multiPrefix = '',
      this.isDataPatchLocked = false,
      this.isPowerPatchLocked = false,
      this.delimiter = '.',
      this.hybridIds = const {}});

  const LocationModel.none()
      : uid = 'none',
        name = '',
        multiPrefix = '',
        isDataPatchLocked = false,
        isPowerPatchLocked = false,
        color = const LabelColorModel.none(),
        delimiter = '',
        hybridIds = const {};

  bool get isHybrid => hybridIds.isNotEmpty;

  bool matchesHybridLocation(Set<String> locationIds) {
    return hybridIds.difference(locationIds).isEmpty;
  }

  LocationModel copyWith({
    String? uid,
    String? name,
    LabelColorModel? color,
    String? multiPrefix,
    bool? isPowerPatchLocked,
    bool? isDataPatchLocked,
    String? delimiter,
    Set<String>? hybridIds,
  }) {
    return LocationModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      color: color ?? this.color,
      multiPrefix: multiPrefix ?? this.multiPrefix,
      isPowerPatchLocked: isPowerPatchLocked ?? this.isPowerPatchLocked,
      isDataPatchLocked: isDataPatchLocked ?? this.isDataPatchLocked,
      delimiter: delimiter ?? this.delimiter,
      hybridIds: hybridIds ?? this.hybridIds,
    );
  }

  String getPrefixedNameByType(Outlet outlet, int number) {
    return switch (outlet) {
      PowerMultiOutletModel _ => getPrefixedPowerMulti(number),
      DataPatchModel _ => getPrefixedDataPatch(number),
      DataMultiModel _ => getPrefixedDataMultiPatch(number),
      _ => throw UnimplementedError(
          'No handling for outlet Type ${outlet.runtimeType}'),
    };
  }

  String getPrefixedDataPatch(int? patchNumber, {String? parentMultiName}) {
    if (this == const LocationModel.none()) {
      return 'No Location';
    }

    if (parentMultiName != null) {
      final patchNumberTrailer = patchNumber == null ? '' : ' - $patchNumber';

      return '$parentMultiName$patchNumberTrailer';
    } else if (patchNumber == null) {
      return multiPrefix;
    }
    return '$multiPrefix$delimiter$patchNumber';
  }

  String getPrefixedDataMultiPatch(int? patchNumber) {
    if (this == const LocationModel.none()) {
      return 'No Location';
    }

    if (patchNumber == null) {
      return multiPrefix;
    }

    return '$multiPrefix$delimiter$patchNumber';
  }

  String getPrefixedPowerMulti(int? multiOutlet) {
    if (this == const LocationModel.none()) {
      return 'No Multi';
    }

    if (multiOutlet == null) {
      return multiPrefix;
    }

    return '$multiPrefix$delimiter$multiOutlet';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'color': color.toMap(),
      'multiPrefix': multiPrefix,
      'isPowerPatchLocked': isPowerPatchLocked,
      'isDataPatchLocked': isDataPatchLocked,
      'delimiter': delimiter,
      'hybridIds': hybridIds.toList(),
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] is int
          ? const LabelColorModel.none()
          : LabelColorModel.fromMap(map['color']),
      multiPrefix: map['multiPrefix'] ?? '',
      isPowerPatchLocked: map['isPowerPatchLocked'] ?? false,
      isDataPatchLocked: map['isDataPatchLocked'] ?? false,
      delimiter: map['delimiter'] ?? '',
      hybridIds: map['hybridIds'] == null
          ? const {}
          : map['hybridIds'].map((x) => x.toString()).toSet(),
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationModel.fromJson(String source) =>
      LocationModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LocationModel(uid: $uid, name: $name, color: $color, multiPrefix: $multiPrefix)';
  }

  static LabelColorModel matchColor(String locationName) {
    final lookup = <RegExp, NamedColorModel>{
      // Red
      RegExp(r'red', caseSensitive: false): NamedColors.red,
      RegExp(r'LX1', caseSensitive: false): NamedColors.red,
      RegExp(r'DS Truss', caseSensitive: false): NamedColors.red,

      // White
      RegExp(r'white', caseSensitive: false): NamedColors.white,
      RegExp(r'LX2', caseSensitive: false): NamedColors.white,
      RegExp(r'MS Truss', caseSensitive: false): NamedColors.white,

      // Blue
      RegExp(r'blue ', caseSensitive: false): NamedColors.blue,
      RegExp(r'LX3', caseSensitive: false): NamedColors.blue,
      RegExp(r'US Truss', caseSensitive: false): NamedColors.blue,

      // Green
      RegExp(r'green ', caseSensitive: false): NamedColors.green,
      RegExp(r'LX4', caseSensitive: false): NamedColors.green,

      // Brown
      RegExp(r'brown ', caseSensitive: false): NamedColors.brown,
      RegExp(r'LX5', caseSensitive: false): NamedColors.brown,

      // Orange
      RegExp(r'SR ', caseSensitive: false): NamedColors.orange,
      RegExp(r'Stage Right ', caseSensitive: false): NamedColors.orange,

      // Yellow
      RegExp(r'SL ', caseSensitive: false): NamedColors.yellow,
      RegExp(r'Stage Left ', caseSensitive: false): NamedColors.yellow,

      // Purple
      RegExp(r'Pyro', caseSensitive: false): NamedColors.purple,
      RegExp(r'Pod', caseSensitive: false): NamedColors.purple,

      // Grey
      RegExp(r'DSL', caseSensitive: false): NamedColors.grey,
      RegExp(r'DSC', caseSensitive: false): NamedColors.grey,
      RegExp(r'DSR', caseSensitive: false): NamedColors.grey,
      RegExp(r'MSL', caseSensitive: false): NamedColors.grey,
      RegExp(r'MSC', caseSensitive: false): NamedColors.grey,
      RegExp(r'MSR', caseSensitive: false): NamedColors.grey,
      RegExp(r'USL', caseSensitive: false): NamedColors.grey,
      RegExp(r'USC', caseSensitive: false): NamedColors.grey,
      RegExp(r'USR', caseSensitive: false): NamedColors.grey,
      RegExp(r'DS', caseSensitive: false): NamedColors.grey,
      RegExp(r'MS', caseSensitive: false): NamedColors.grey,
      RegExp(r'US', caseSensitive: false): NamedColors.grey,
      RegExp(r'TOWER', caseSensitive: false): NamedColors.grey,
      RegExp(r'VERT', caseSensitive: false): NamedColors.grey,
    };

    final key =
        lookup.keys.firstWhereOrNull((regex) => regex.hasMatch(locationName));

    if (key == null) {
      return const LabelColorModel.none();
    }

    return LabelColorModel(colors: [
      lookup[key]!,
    ]);
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

      // Locations
      RegExp('Front', caseSensitive: false): 'FRT ',
      RegExp('Mid', caseSensitive: false): 'MID ',
      RegExp('Back', caseSensitive: false): 'BACK ',

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
      RegExp('DSR ', caseSensitive: false): 'DSR',
      RegExp('USR ', caseSensitive: false): 'USR',
      RegExp('DSL ', caseSensitive: false): 'DSL',
      RegExp('USL ', caseSensitive: false): 'USL',
      RegExp('DSC ', caseSensitive: false): 'DSC',
      RegExp('USC ', caseSensitive: false): 'USC',
      RegExp('MSC ', caseSensitive: false): 'MSC',
      RegExp('MSL ', caseSensitive: false): 'MSL',
      RegExp('MSR ', caseSensitive: false): 'MSR',
      RegExp('SR ', caseSensitive: false): 'SR',
      RegExp('SL ', caseSensitive: false): 'SL',
      RegExp('US ', caseSensitive: false): 'US',
      RegExp('DS ', caseSensitive: false): 'DS',
      RegExp('CS ', caseSensitive: false): 'CS',

      // Shapes
      RegExp('Circle', caseSensitive: false): 'CIRC ',
      RegExp('Spine', caseSensitive: false): 'SPINE',

      // Fingers
      RegExp('Finger.*1', caseSensitive: false): 'F1',
      RegExp('Finger.*2', caseSensitive: false): 'F2',
      RegExp('Finger.*3', caseSensitive: false): 'F3',
      RegExp('Finger.*4', caseSensitive: false): 'F4',
      RegExp('Finger.*5', caseSensitive: false): 'F5',
      RegExp('Finger.*6', caseSensitive: false): 'F6',
      RegExp('Finger.*7', caseSensitive: false): 'F7',
      RegExp('Finger.*8', caseSensitive: false): 'F8',
      RegExp('Finger.*9', caseSensitive: false): 'F9',
      RegExp('Finger.*10', caseSensitive: false): 'F10',
      RegExp('Finger.*11', caseSensitive: false): 'F11',
      RegExp('Finger.*12', caseSensitive: false): 'F12',
      RegExp('Finger.*13', caseSensitive: false): 'F13',
      RegExp('Finger.*14', caseSensitive: false): 'F14',
      RegExp('Finger.*15', caseSensitive: false): 'F15',
      RegExp('Finger.*16', caseSensitive: false): 'F16',

      // Numeric Verticals
      RegExp('Vert.*1', caseSensitive: false): 'V1',
      RegExp('Vert.*2', caseSensitive: false): 'V2',
      RegExp('Vert.*3', caseSensitive: false): 'V3',
      RegExp('Vert.*4', caseSensitive: false): 'V4',
      RegExp('Vert.*5', caseSensitive: false): 'V5',
      RegExp('Vert.*6', caseSensitive: false): 'V6',
      RegExp('Vert.*7', caseSensitive: false): 'V7',
      RegExp('Vert.*8', caseSensitive: false): 'V8',
      RegExp('Vert.*9', caseSensitive: false): 'V9',
      RegExp('Vert.*10', caseSensitive: false): 'V10',
      RegExp('Vert.*11', caseSensitive: false): 'V11',
      RegExp('Vert.*12', caseSensitive: false): 'V12',

      // Numeric Towers
      RegExp('Tower.*1', caseSensitive: false): 'T1',
      RegExp('Tower.*2', caseSensitive: false): 'T2',
      RegExp('Tower.*3', caseSensitive: false): 'T3',
      RegExp('Tower.*4', caseSensitive: false): 'T4',
      RegExp('Tower.*5', caseSensitive: false): 'T5',
      RegExp('Tower.*6', caseSensitive: false): 'T6',
      RegExp('Tower.*7', caseSensitive: false): 'T7',
      RegExp('Tower.*8', caseSensitive: false): 'T8',
      RegExp('Tower.*9', caseSensitive: false): 'T9',
      RegExp('Tower.*10', caseSensitive: false): 'T10',
      RegExp('Tower.*11', caseSensitive: false): 'T11',
      RegExp('Tower.*12', caseSensitive: false): 'T12',

      // Numeric Trusses
      RegExp('Truss.*1', caseSensitive: false): 'T1',
      RegExp('Truss.*2', caseSensitive: false): 'T2',
      RegExp('Truss.*3', caseSensitive: false): 'T3',
      RegExp('Truss.*4', caseSensitive: false): 'T4',
      RegExp('Truss.*5', caseSensitive: false): 'T5',
      RegExp('Truss.*6', caseSensitive: false): 'T6',
      RegExp('Truss.*7', caseSensitive: false): 'T7',
      RegExp('Truss.*8', caseSensitive: false): 'T8',
      RegExp('Truss.*9', caseSensitive: false): 'T9',
      RegExp('Truss.*10', caseSensitive: false): 'T10',
      RegExp('Truss.*11', caseSensitive: false): 'T11',
      RegExp('Truss.*12', caseSensitive: false): 'T12',
      RegExp('Truss.*13', caseSensitive: false): 'T13',
      RegExp('Truss.*14', caseSensitive: false): 'T14',
      RegExp('Truss.*15', caseSensitive: false): 'T15',
      RegExp('Truss.*16', caseSensitive: false): 'T16',
      RegExp('Truss.*17', caseSensitive: false): 'T17',
      RegExp('Truss.*18', caseSensitive: false): 'T18',
      RegExp('Truss.*19', caseSensitive: false): 'T19',
      RegExp('Truss.*20', caseSensitive: false): 'T20',
      RegExp('Truss.*21', caseSensitive: false): 'T21',
      RegExp('Truss.*22', caseSensitive: false): 'T22',
      RegExp('Truss.*23', caseSensitive: false): 'T23',
      RegExp('Truss.*24', caseSensitive: false): 'T24',

      // Numeric Pods
      RegExp('Pod.*1', caseSensitive: false): 'P1',
      RegExp('Pod.*2', caseSensitive: false): 'P2',
      RegExp('Pod.*3', caseSensitive: false): 'P3',
      RegExp('Pod.*4', caseSensitive: false): 'P4',
      RegExp('Pod.*5', caseSensitive: false): 'P5',
      RegExp('Pod.*6', caseSensitive: false): 'P6',
      RegExp('Pod.*7', caseSensitive: false): 'P7',
      RegExp('Pod.*8', caseSensitive: false): 'P8',
      RegExp('Pod.*9', caseSensitive: false): 'P9',
      RegExp('Pod.*10', caseSensitive: false): 'P10',
      RegExp('Pod.*11', caseSensitive: false): 'P11',
      RegExp('Pod.*12', caseSensitive: false): 'P12',
      RegExp('Pod.*13', caseSensitive: false): 'P13',
      RegExp('Pod.*14', caseSensitive: false): 'P14',
      RegExp('Pod.*15', caseSensitive: false): 'P15',
      RegExp('Pod.*16', caseSensitive: false): 'P16',

      // Alpha Numerics
      RegExp('A ', caseSensitive: false): 'A',
      RegExp('B ', caseSensitive: false): 'B',
      RegExp('C ', caseSensitive: false): 'C',
      RegExp('D ', caseSensitive: false): 'D',
      RegExp('E ', caseSensitive: false): 'E',
      RegExp('F ', caseSensitive: false): 'F',
      RegExp('G ', caseSensitive: false): 'G',
      RegExp('H ', caseSensitive: false): 'H',
    };

    final key =
        lookup.keys.firstWhereOrNull((regex) => regex.hasMatch(locationName));

    if (key == null) {
      return '';
    }

    return lookup[key]!;
  }

  @override
  Map<DiffPropertyName, Object> getDiffValues() => {
        DiffPropertyName.name: name,
        DiffPropertyName.color: color,
        DiffPropertyName.multiPrefix: multiPrefix,
        DiffPropertyName.delimiter: delimiter,
      };
}
