import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

mixin DiffComparable {
  PropertyDeltaSet calculateDeltas(DiffComparable other) {
    final otherValues = other.getDiffValues();

    final diffSet = getDiffValues()
        .entries
        .map((entry) {
          final propertyName = entry.key;
          final valueA = entry.value;
          final Object? valueB = otherValues[entry.key];

          // If both values have the [DiffComparable] mixin, then drill down into them.
          if (valueA is DiffComparable && valueB is DiffComparable) {
            return valueA.calculateDeltas(valueB).properties;
          }

          if (valueA != valueB) {
            return {propertyName};
          } else {
            return {null};
          }
        })
        .flattened
        .nonNulls
        .toList();

    return PropertyDeltaSet(diffSet);
  }

  Map<PropertyDeltaName, Object> getDiffValues();
}

class PropertyDeltaSet {
  final Set<PropertyDeltaName> properties;

  PropertyDeltaSet(List<PropertyDeltaName> properties)
      : properties = _convertToSet(properties);

  const PropertyDeltaSet.empty() : properties = const {};

  DiffState lookup(PropertyDeltaName name) =>
      properties.contains(name) ? DiffState.changed : DiffState.unchanged;

  static Set<PropertyDeltaName> _convertToSet(
      List<PropertyDeltaName> properties) {
    final asSet = properties.toSet();

    if (kDebugMode) {
      // Pretty expensive to calculate this. So only do it in debug mode.
      if (asSet.length != properties.length) {
        final (_, duplicatedPropertyNames) = properties.fold<
            (
              Set<PropertyDeltaName> seen,
              Set<PropertyDeltaName> duplicates
            )>(({}, {}), (accum, current) {
          final (seenAlready, duplicatedNames) = accum;

          return (
            {...seenAlready, current},
            {
              ...duplicatedNames,
              if (seenAlready.contains(current)) current,
            }
          );
        });

        throw 'PropertyDeltaName Shadowing error: DiffComparable.calculateDeltas() detected multiple instances of values with the same DeltaPropertyName. '
            'This is likely due to a child object reusing the same DeltaPropertyName as a parent item. This means that the Parent item Delta state gets shadowed '
            'by the childs state leading to inconsitencies. To fix this, ensure the child items DeltaPropertyNames are specific enough to that child. \n'
            'Duplicated property names: ${duplicatedPropertyNames.map((item) => item.name).join(', ')}';
      }
    }

    return asSet;
  }
}
