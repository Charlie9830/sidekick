// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/balancer/models/balancer_outlet_model.dart';
import 'package:sidekick/balancer/models/balancer_power_patch_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

class BalancerMultiOutletModel implements Comparable<BalancerMultiOutletModel> {
  final String uid;
  final String locationId;
  final int desiredSpareCircuits;
  final int number;
  final List<BalancerOutletModel> children;
  final String name;

  BalancerMultiOutletModel({
    required this.uid,
    required this.locationId,
    this.number = 0,
    this.name = '',
    required this.desiredSpareCircuits,
    required this.children,
  });

  const BalancerMultiOutletModel.none()
      : uid = '',
        locationId = '',
        name = '',
        number = 0,
        desiredSpareCircuits = 0,
        children = const [];

  factory BalancerMultiOutletModel.fromMultiOutletWithoutChildren(
      PowerMultiOutletModel multi) {
    return BalancerMultiOutletModel(
        uid: multi.uid,
        locationId: multi.locationId,
        desiredSpareCircuits: multi.desiredSpareCircuits,
        children: []);
  }

  @override
  int compareTo(BalancerMultiOutletModel other) {
    return number - other.number;
  }

  BalancerMultiOutletModel copyWith({
    String? uid,
    String? locationId,
    int? desiredSpareCircuits,
    int? number,
    List<BalancerOutletModel>? children,
    String? name,
  }) {
    return BalancerMultiOutletModel(
      uid: uid ?? this.uid,
      locationId: locationId ?? this.locationId,
      desiredSpareCircuits: desiredSpareCircuits ?? this.desiredSpareCircuits,
      number: number ?? this.number,
      children: children ?? this.children,
      name: name ?? this.name,
    );
  }
}
