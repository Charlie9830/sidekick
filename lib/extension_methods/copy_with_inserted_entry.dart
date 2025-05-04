extension OrderedMapOperations<K, V> on Map<K, V> {
  Map<K, V> copyWithInsertedEntry(int index, MapEntry<K, V> item) {
    final workingMap = Map<K, V>.from(this);
    workingMap.remove(item.key);

    final entryList = workingMap.entries.toList();

    entryList.insert(index, item);

    return Map<K, V>.fromEntries(entryList);
  }
}
