class NumericSpan {
  final int startsAt;
  final List<int> elements;
  int? endsAt;

  NumericSpan({
    required this.startsAt,
    required this.elements,
    this.endsAt,
  });

  @override
  String toString() {
    return 'NumericSpan: $elements';
  }

  /// Returns a list of [NumericSpan]s.
  static List<NumericSpan> createSpans(List<int> numbers) {
    final List<NumericSpan> spans = [];
    NumericSpan? currentSpan;

    for (final (index, number) in numbers.indexed) {
      currentSpan ??= NumericSpan(startsAt: number, elements: []);

      currentSpan.elements.add(number);

      // Peek ahead at the next Fixture. Null if not existing.
      final nextNumber = index < numbers.length - 1 ? numbers[index + 1] : null;

      if (nextNumber == null) {
        // No more Numbers. Close and Commit the current Span.
        currentSpan.endsAt = number;
        spans.add(currentSpan);
        currentSpan = null;
        continue;
      }
    }

    return spans;
  }
}
