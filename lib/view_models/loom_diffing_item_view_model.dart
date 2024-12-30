
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/loom_item_view_model.dart';

class LoomDiffingItemViewModel {
  final LoomItemViewModel? current;
  final LoomItemViewModel? original;

  final Set<PropertyDelta> deltas;

  LoomDiffingItemViewModel({
    required this.current,
    required this.original,
    required this.deltas,
  });  
}
