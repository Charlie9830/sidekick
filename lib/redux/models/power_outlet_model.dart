import 'dart:convert';

class PowerOutletModel {
  final int phase;
  final bool isSpare;
  final int multiPatch;
  final List<String> fixtureIds;
  final double load;

  PowerOutletModel({
    required this.phase,
    required this.multiPatch,
    required this.fixtureIds,
    required this.load,
    this.isSpare = false,
  });

  PowerOutletModel.spare({
    required this.phase,
    required this.multiPatch,
  })  : isSpare = true,
        load = 0,
        fixtureIds = [];

  PowerOutletModel copyWith({
    int? phase,
    bool? isSpare,
    String? multiOutletId,
    String? locationId,
    int? multiPatch,
    List<String>? fixtureIds,
    double? load,
  }) {
    return PowerOutletModel(
      phase: phase ?? this.phase,
      isSpare: isSpare ?? this.isSpare,
      multiPatch: multiPatch ?? this.multiPatch,
      fixtureIds: fixtureIds ?? this.fixtureIds,
      load: load ?? this.load,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase,
      'isSpare': isSpare,
      'multiPatch': multiPatch,
      'fixtureIds': fixtureIds,
      'load': load,
    };
  }

  factory PowerOutletModel.fromMap(Map<String, dynamic> map) {
    return PowerOutletModel(
      phase: map['phase']?.toInt() ?? 0,
      isSpare: map['isSpare'] ?? false,
      multiPatch: map['multiPatch']?.toInt() ?? 0,
      fixtureIds: List<String>.from(map['fixtureIds']),
      load: map['load']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerOutletModel.fromJson(String source) =>
      PowerOutletModel.fromMap(json.decode(source));
}
