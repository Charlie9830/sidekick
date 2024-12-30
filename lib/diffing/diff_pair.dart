import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class DiffPair<T extends DiffComparable> {
  final T? original;
  final T? current;

  DiffPair(this.current, this.original);

  Set<PropertyDelta> get deltas => original == null || current == null
      ? {}
      : current!.calculateDeltas(original!);
}
