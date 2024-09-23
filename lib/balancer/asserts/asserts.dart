import 'package:collection/collection.dart';
import 'package:sidekick/balancer/models/balancer_power_outlet_model.dart';

bool checkPhaseOrdering(List<BalancerPowerOutletModel> outlets) {
  final slicesOf3 = outlets.slices(3);

  for (var trio in slicesOf3) {
    if (trio[0].phase != 1 || trio[1].phase != 2 || trio[2].phase != 3) {
      return false;
    }
  }

  return true;
}

bool checkOutletQty(int qty) {
  return qty % 6 == 0;
}
