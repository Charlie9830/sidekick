enum DeltaPropertyName {
  none,
  name,
  length,
  permanentComposition,
  loomType,
  loomClass,
  isDrop,
  hasVariedLengthChildren,
  notes,
  cableType,
  isSpare,
  delimiter,
  multiPrefix,
  color,
  label,
  locationId,
  isExtension,
  fixtureId,
  fixtureType,
  universe,
  address, loomId, outletId, parentMultiId,
}

enum DiffState {
  unchanged,
  added,
  changed,
  deleted,
}

class PropertyDelta {
  final DeltaPropertyName name;
  final DiffState diff;

  PropertyDelta(
    this.name,
    this.diff,
  );

  PropertyDelta.modified(this.name) : diff = DiffState.changed;

  @override
  int get hashCode => name.hashCode ^ diff.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PropertyDelta && name == other.name && diff == other.diff;
  }
}
