import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

class BalancerResult {
  final List<PowerOutletModel> outlets;
  final PhaseLoad load;

  BalancerResult(this.outlets, this.load);
}
