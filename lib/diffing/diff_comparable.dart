import 'package:collection/collection.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

mixin DiffComparable {
  Set<PropertyDelta> calculateDeltas(DiffComparable other) {
    final otherValues = other.getDiffValues();

    return getDiffValues()
        .entries
        .map((entry) {
          final Object valueA = entry.value;
          final Object? valueB = otherValues[entry.key];

          // If both values have the [DiffComparable] mixin, then drill down into them.
          if (valueA is DiffComparable && valueB is DiffComparable) {
            return valueA.calculateDeltas(valueB);
          }

          if (valueA != valueB) {
            return {PropertyDelta.modified(entry.key)};
          } else {
            return {null};
          }
        })
        .flattened
        .nonNulls
        .toSet();
  }

  Map<DeltaPropertyName, Object> getDiffValues();
}
