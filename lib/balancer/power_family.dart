// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/balancer/models/balancer_power_outlet_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';

class PowerFamily {
  final PowerMultiOutletModel parent;
  final List<BalancerPowerOutletModel> children;

  PowerFamily({required this.parent, required this.children});

  PowerFamily copyWith({
    PowerMultiOutletModel? parent,
    List<BalancerPowerOutletModel>? children,
  }) {
    return PowerFamily(
      parent: parent ?? this.parent,
      children: children ?? this.children,
    );
  }
}
