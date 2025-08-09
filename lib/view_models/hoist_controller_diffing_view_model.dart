import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';

class HoistControllerDiffingViewModel {
  final HoistControllerViewModel? original;
  final HoistControllerViewModel? current;
  final DiffState overallDiff;
  final PropertyDeltaSet deltas;
  final Map<String, HoistChannelDelta> channelDeltas;

  HoistControllerDiffingViewModel({
    required this.original,
    required this.current,
    required this.overallDiff,
    this.deltas = const PropertyDeltaSet.empty(),
    required this.channelDeltas,
  });
}
