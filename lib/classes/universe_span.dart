import 'package:sidekick/redux/models/fixture_model.dart';

class UniverseSpan {
  final int universe;
  final FixtureModel startsAt;
  final List<String> fixtureIds;
  FixtureModel? endsAt;

  UniverseSpan({
    required this.universe,
    required this.startsAt,
    required this.fixtureIds,
    this.endsAt,
  });

  /// Returns a list of [UniverseSpan]s. A span will be broken down by Universe, as well as breaks in the [FixtureModel] sequence numbers.
  static List<UniverseSpan> createSpans(List<FixtureModel> fixtures) {
    final List<UniverseSpan> spans = [];
    UniverseSpan? currentSpan;

    for (final (index, fixture) in fixtures.indexed) {
      currentSpan ??= UniverseSpan(
          universe: fixture.dmxAddress.universe,
          startsAt: fixture,
          fixtureIds: []);

      currentSpan.fixtureIds.add(fixture.uid);

      // Peek ahead at the next Fixture. Null if not existing.
      final nextFixture =
          index < fixtures.length - 1 ? fixtures[index + 1] : null;

      if (nextFixture == null) {
        // No more Fixtures. Close and Commit the current Span.
        currentSpan.endsAt = fixture;
        spans.add(currentSpan);
        currentSpan = null;
        continue;
      }

      if (nextFixture.dmxAddress.universe != fixture.dmxAddress.universe) {
        // Close and Commit the current Span.
        currentSpan.endsAt = fixture;
        spans.add(currentSpan);
        currentSpan = null;
        continue;
      }

      if (nextFixture.sequence != fixture.sequence + 1) {
        // Close and Commit the current Span.
        currentSpan.endsAt = fixture;
        spans.add(currentSpan);
        currentSpan = null;
        continue;
      }
    }

    return spans;
  }
}
