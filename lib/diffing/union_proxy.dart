enum ProxySource {
  original,
  current,
}

class UnionProxy<T> {
  final ProxySource source;
  final T element;

  UnionProxy(this.source, this.element);
}
