import 'package:sidekick/balancer/models/balancer_fixture_model.dart';

class PowerSpan {
  final String locationId;
  final BalancerFixtureModel startsAt;
  final List<BalancerFixtureModel> fixtures;
  BalancerFixtureModel? endsAt;

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
  static List<PowerSpan> createSpans(List<BalancerFixtureModel> fixtures) {
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

      if (nextFixture.locationId != fixture.locationId) {
        // New Location. Close and Commit the Current Span.
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
