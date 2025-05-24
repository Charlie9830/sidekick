import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/balancer/models/balancer_outlet_model.dart';

class BalancerResult {
  final List<BalancerOutletModel> outlets;
  final PhaseLoad load;

  BalancerResult(this.outlets, this.load);
}
