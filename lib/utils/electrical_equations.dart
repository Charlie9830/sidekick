import 'dart:math';

/// Calculates a Ratio of Phase imbalance between 0 (in Balance) and 1 (Out of balance)
double calculateBalanceRatio(double a, double b, double c) {
  final neutralCurrent = calculateNeutralCurrent(a, b, c);

  return (neutralCurrent / (a + b + c));
}

/// Calculates the expected Current flow down the Neutral line in Amps.
double calculateNeutralCurrent(double a, double b, double c) {
  double aSquared = a * a;
  double bSquared = b * b;
  double cSquared = c * c;

  double abMulti = a * b;
  double acMulti = a * c;
  double bcMulti = b * c;

  return sqrt((aSquared + bSquared + cSquared - abMulti - acMulti - bcMulti));
}
