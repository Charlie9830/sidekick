import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';

class FixtureDiffingItemViewModel {
  final FixtureTableRowViewModel? original;
  final FixtureTableRowViewModel? current;
  final DiffState overallDiff;
  final PropertyDeltaSet deltas;

  FixtureDiffingItemViewModel({
    required this.original,
    required this.current,
    required this.overallDiff,
    this.deltas = const PropertyDeltaSet.empty(),
  });
}
