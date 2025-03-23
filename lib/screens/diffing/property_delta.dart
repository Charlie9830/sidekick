enum DiffPropertyName {
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
  address,
}

enum ChangeType {
  added,
  deleted,
  none,
  modified,
}

class PropertyDelta {
  final DiffPropertyName name;
  final ChangeType type;

  PropertyDelta(
    this.name,
    this.type,
  );

  PropertyDelta.modified(this.name) : type = ChangeType.modified;

  @override
  int get hashCode => name.hashCode ^ type.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PropertyDelta && name == other.name && type == other.type;
  }
}
