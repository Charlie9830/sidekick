import 'dart:collection';

extension QueuePop<T> on Queue<T> {
  Iterable<T> pop(int ammount) sync* {
    int count = 1;
    while (isNotEmpty && count <= ammount) {
      count++;
      yield removeFirst();
    }
  }
}

extension OrderedMapOperations<K, V> on Map<K, V> {
  Map<K, V> copyWithInsertedEntry(int index, MapEntry<K, V> item) {
    final entryList = entries.toList();

    entryList.insert(index, item);

    return Map<K, V>.fromEntries(entryList);
  }
}