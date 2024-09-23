import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/balancer/models/balancer_power_outlet_model.dart';

class BalancerResult {
  final List<BalancerPowerOutletModel> outlets;
  final PhaseLoad load;

  BalancerResult(this.outlets, this.load);
}
