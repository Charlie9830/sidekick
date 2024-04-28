import 'dart:math';

/// Calculates a Ratio of Phase imbalance between 0 (in Balance) and 1 (Out of balance)
double calculateImbalanceRatio(double a, double b, double c) {
  final neutralCurrent = calculateNeutralCurrent(a, b, c);

  if (neutralCurrent == 0) {
    return 0;
  }

  return (neutralCurrent / ((a + b + c) / 3));
}

/// Calculates the expected Current flow down the Neutral line in Amps.
double calculateNeutralCurrent(double a, double b, double c) {
  if (a == 0 && b == 0 && c == 0) {
    return 0;
  }

  if ([a, b, c].every((item) => item == a)) {
    return 0;
  }

  double aSquared = a * a;
  double bSquared = b * b;
  double cSquared = c * c;

  double abMulti = a * b;
  double acMulti = a * c;
  double bcMulti = b * c;

  final rooted =
      sqrt((aSquared + bSquared + cSquared - abMulti - acMulti - bcMulti));

  if (rooted.isNaN || rooted.isNegative || rooted.isInfinite) {
    print(
        'Neutral Calculation resulted in a NaN or Negative or Infinite. Result = $rooted');
    return 0;
  }

  return rooted;
}

/// Returns the Median value of a set of numbers [a].
double median(List<double> a) {
  var middle = a.length ~/ 2;
  if (a.length % 2 == 1) {
    return a[middle];
  } else {
    return (a[middle - 1] + a[middle]) / 2.0;
  }
}
