extension AddIfAbsentElseRemove<E> on Set<E> {
  /// Will Add the [element] if it doesn't already exist, otherwise it will remove the corresponding element.
  void addIfAbsentElseRemove(E element) {
    if (contains(element) == false) {
      add(element);
    } else {
      remove(element);
    }
  }
}
