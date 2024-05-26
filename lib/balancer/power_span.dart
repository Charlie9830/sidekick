import 'package:sidekick/redux/models/fixture_model.dart';

class PowerSpan {
  final String locationId;
  final FixtureModel startsAt;
  final List<FixtureModel> fixtures;
  FixtureModel? endsAt;

  PowerSpan({
    required this.locationId,
    required this.startsAt,
    required this.fixtures,
    this.endsAt,
  });

  @override
  String toString() {
    return 'PowerSpan: [${fixtures.map((fix) => fix.fid)}]';
  }

  /// Returns a list of [PowerSpan]s. A span will be broken down by locationId, as well as breaks in the [FixtureModel] sequence numbers.
  static List<PowerSpan> createSpans(List<FixtureModel> fixtures) {
    final List<PowerSpan> spans = [];
    PowerSpan? currentSpan;

    for (final (index, fixture) in fixtures.indexed) {
      currentSpan ??= PowerSpan(
          locationId: fixture.locationId, startsAt: fixture, fixtures: []);

      currentSpan.fixtures.add(fixture);

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
