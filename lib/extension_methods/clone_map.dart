extension CloneMap<K, V> on Map<K, V> {
  Map<K, V> clone() => Map<K, V>.from(this);
}
