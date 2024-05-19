import 'package:sidekick/balancer/balancer_result.dart';
import 'package:sidekick/balancer/phase_load.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/power_multi_outlet_model.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';

abstract class Balancer {
  Map<PowerMultiOutletModel, List<PowerOutletModel>> assignToOutlets({
    required List<FixtureModel> fixtures,
    required List<PowerMultiOutletModel> multiOutlets,
    int maxSequenceBreak = 4,
  });

  BalancerResult balanceOutlets(
    List<PowerOutletModel> outlets, {
    double balanceTolerance = 0.5,
    PhaseLoad initialLoad = const PhaseLoad.zero(),
  });
}
