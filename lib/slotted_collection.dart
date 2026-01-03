class SlottedCollection<T> {
  int _slotCount;
  final List<Slot<T>> _items;

  SlottedCollection._(List<Slot<T>> items, int slotCount)
      : _items = items,
        _slotCount = slotCount;

  factory SlottedCollection.fromList(int slotCount, List<T> items) {
    assert(slotCount >= items.length, 'Qty cannot be less than items.length');

    return SlottedCollection._(
        List<Slot<T>>.generate(slotCount, (index) {
          final item = items.elementAtOrNull(index);
          return Slot<T>(
            item,
            index,
            item != null,
          );
        }),
        slotCount);
  }

  int get length => _slotCount;

  Slot<T> operator [](int index) {
    return _items[index];
  }

  int get availableSlots =>
      _items.where((item) => item.occupied == false).length;
}

class Slot<T> {
  final T? value;
  final int index;
  final bool occupied;

  Slot(this.value, this.index, this.occupied);
}
