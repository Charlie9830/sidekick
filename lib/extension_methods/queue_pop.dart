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
