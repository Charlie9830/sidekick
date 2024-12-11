extension AddAllIfAbsentElseRemove<E> on Set<E> {
  void addAllIfAbsentElseRemove(Iterable<E> elements) {
    for (var element in elements) {
      if (contains(element) == false) {
        add(element);
      } else {
        remove(element);
      }
    }
  }
}
