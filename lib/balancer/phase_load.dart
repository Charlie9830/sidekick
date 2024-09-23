import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/utils/electrical_equations.dart' as ee;

class PhaseLoad {
  final double a;
  final double b;
  final double c;

  PhaseLoad(this.a, this.b, this.c);

  const PhaseLoad.zero()
      : a = 0,
        b = 0,
        c = 0;

  double get neutral => ee.calculateNeutralCurrent(a, b, c);
  double get median => ee.median([a, b, c]);
  double get ratio => ee.calculateImbalanceRatio(a, b, c);

  (IndexedLoad a, IndexedLoad b, IndexedLoad c) get asIndexedLoads =>
      (IndexedLoad(0, a), IndexedLoad(1, b), IndexedLoad(2, c));

  PhaseLoad operator +(PhaseLoad other) =>
      PhaseLoad(a + other.a, b + other.b, c + other.c);

  @override
  String toString() {
    return 'PhaseLoad { ${a.round()}A  |  ${b.round()}A  |  ${c.round()}A }';
  }

  static double calculateTotalPhaseLoad(
      List<PowerOutletModel> outlets, int phaseNumber) {
    assert(phaseNumber >= 1 && phaseNumber <= 3,
        'Phase number is out of range, Allowed range 1 to 3, given value $phaseNumber');

    return outlets
        .where((outlet) => outlet.phase == phaseNumber)
        .map((outlet) => outlet.load)
        .fold(0, (prev, value) => prev + value);
  }
}

/// Represents a phase loading along with it's ZERO BASED index.
class IndexedLoad {
  final int index;
  double load;

  IndexedLoad(int index, this.load) : index = _assertZeroBasedIndex(index);

  /// Asserts that the provided [index] is Zero based.
  static int _assertZeroBasedIndex(int index) {
    if (index >= 0 && index <= 2) {
      return index;
    }

    throw ArgumentError(
        "The [index] parameter provided to [IndexedLoad] must be Zero based. Value received = $index");
  }
}
