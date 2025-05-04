import 'dart:convert';

class DMXAddressModel {
  final int universe;
  final int address;

  DMXAddressModel({
    required this.universe,
    required this.address,
  });

  const DMXAddressModel.unknown()
      : address = 0,
        universe = 0;

  factory DMXAddressModel.fromGlobal(int globalAddress) {
    if (globalAddress == 0) {
      return const DMXAddressModel.unknown();
    }

    return DMXAddressModel(
        universe: (globalAddress / 512).ceil(), address: globalAddress % 512);
  }

  DMXAddressModel copyWith({
    int? address,
    int? universe,
  }) {
    return DMXAddressModel(
      address: address ?? this.address,
      universe: universe ?? this.universe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'localAddress': address,
      'universe': universe,
    };
  }

  factory DMXAddressModel.fromMap(Map<String, dynamic> map) {
    return DMXAddressModel(
      address: map['localAddress']?.toInt() ?? 0,
      universe: map['universe']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory DMXAddressModel.fromJson(String source) =>
      DMXAddressModel.fromMap(json.decode(source));

  String toSlashNotationString() => '$universe/$address';

  @override
  String toString() =>
      'DMXAddressModel( localAddress: $address, universe: $universe)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DMXAddressModel &&
        other.address == address &&
        other.universe == universe;
  }

  @override
  int get hashCode => address.hashCode ^ universe.hashCode;

  String get formatted => '$universe/$address';
}
