import 'dart:convert';

class DMXAddressModel {
  final int globalAddress;
  final int localAddress;
  final int universe;

  DMXAddressModel({
    required this.globalAddress,
    required this.localAddress,
    required this.universe,
  });

  const DMXAddressModel.unknown()
      : globalAddress = 0,
        localAddress = 0,
        universe = 0;

  DMXAddressModel.fromGlobalAddress(int address)
      : globalAddress = address,
        universe = _convertGlobalAddressToUniverse(address),
        localAddress = _convertGlobalAddressToLocalAddress(address);

  factory DMXAddressModel.fromPatchString(String patch) {
    if (patch.isEmpty) {
      return DMXAddressModel(globalAddress: 0, localAddress: 0, universe: 0);
    }

    final universe = _getUniverseFromPatchString(patch);
    final address = _getLocalAddressFromPatchString(patch);

    return DMXAddressModel.fromGlobalAddress(
        ((universe * 512) + address) - 512);
  }

  static int _getUniverseFromPatchString(String patchString) {
    if (patchString.isEmpty) {
      return 0;
    }

    return int.tryParse(patchString.split('.')[0].trim()) ?? 0;
  }

  static int _getLocalAddressFromPatchString(String patchString) {
    if (patchString.isEmpty) {
      return 0;
    }

    return int.tryParse(patchString.split('.')[1].trim()) ?? 0;
  }

  static int _convertGlobalAddressToUniverse(int address) {
    if (address == 0) return 0;

    return (address / 512).ceil();
  }

  static int _convertGlobalAddressToLocalAddress(int address) {
    return address % 512;
  }

  (int, int) get address => (universe, localAddress);

  DMXAddressModel copyWith({
    int? globalAddress,
    int? localAddress,
    int? universe,
  }) {
    return DMXAddressModel(
      globalAddress: globalAddress ?? this.globalAddress,
      localAddress: localAddress ?? this.localAddress,
      universe: universe ?? this.universe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'globalAddress': globalAddress,
      'localAddress': localAddress,
      'universe': universe,
    };
  }

  factory DMXAddressModel.fromMap(Map<String, dynamic> map) {
    return DMXAddressModel(
      globalAddress: map['globalAddress']?.toInt() ?? 0,
      localAddress: map['localAddress']?.toInt() ?? 0,
      universe: map['universe']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory DMXAddressModel.fromJson(String source) =>
      DMXAddressModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'DMXAddressModel(globalAddress: $globalAddress, localAddress: $localAddress, universe: $universe)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DMXAddressModel &&
        other.globalAddress == globalAddress &&
        other.localAddress == localAddress &&
        other.universe == universe;
  }

  @override
  int get hashCode =>
      globalAddress.hashCode ^ localAddress.hashCode ^ universe.hashCode;
}
