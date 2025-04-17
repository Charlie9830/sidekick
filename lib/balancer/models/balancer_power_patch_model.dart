import 'package:collection/collection.dart';
import 'package:sidekick/balancer/models/balancer_fixture_model.dart';

class BalancerPowerPatchModel {
  final List<BalancerFixtureModel> fixtures;

  BalancerPowerPatchModel({
    this.fixtures = const [],
  });

  BalancerPowerPatchModel.empty() : fixtures = const [];

  bool get isEmpty => fixtures.isEmpty;

  bool get isNotEmpty => fixtures.isNotEmpty;

  double get amps => fixtures
      .map((fixture) => fixture.type.amps)
      .fold(0, (value, element) => value + element);

  BalancerPowerPatchModel copyWith({
    List<BalancerFixtureModel>? fixtures,
  }) {
    return BalancerPowerPatchModel(
      fixtures: fixtures ?? this.fixtures,
    );
  }

  /// Returns true if all Fixtures in the [fixtueres] property are contigously sequenced, that is to say, that each fixture
  /// follows the next one without any breaks in the sequence number. Additionally checks that all fixtures in the collection match
  /// the same Fixture Type.
  bool isContiguous() {
    if (fixtures.isEmpty || fixtures.length == 1) {
      return false;
    }

    final contiguousFixtures = fixtures.whereIndexed((index, current) {
      if (index == 0) {
        return true;
      }
      
      final BalancerFixtureModel? previous =
          fixtures.elementAtOrNull(index - 1);

      if (previous == null) {
        return true;
      }

      if (previous.type.uid != current.type.uid) {
        return false;
      }

      return previous.sequence == current.sequence - 1;
    });

    return contiguousFixtures.length == fixtures.length;
  }

  /// See [isContiguous]. Proxy calls [isContiguous] with the [candidate] appended to the [fixtures] collection.
  bool isContiguousWith(BalancerFixtureModel candidate) {
    return copyWith(fixtures: [...fixtures, candidate]).isContiguous();
  }

  int compareByFid(BalancerPowerPatchModel other) {
    const maxInt = 0x7FFFFFFFFFFFFFFF;

    final a = fixtures.isEmpty ? maxInt : fixtures.first.fid;
    final b = other.fixtures.isEmpty ? maxInt : other.fixtures.first.fid;

    return a - b;
  }

  int compareBySequence(BalancerPowerPatchModel other) {
    const maxInt = 0x7FFFFFFFFFFFFFFF;

    final a = fixtures.isEmpty ? maxInt : fixtures.first.sequence;
    final b = other.fixtures.isEmpty ? maxInt : other.fixtures.first.sequence;

    return a - b;
  }
}
