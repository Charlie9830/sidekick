import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

/// Diff of the breakout cable quantities for a single location between the
/// current project and the loaded comparison project.
class CableQtyDiffingItemViewModel {
  final String locationId;
  final String locationName;
  final DiffState overallDiff;
  final List<CableQtyDelta> deltas;

  CableQtyDiffingItemViewModel({
    required this.locationId,
    required this.locationName,
    required this.overallDiff,
    required this.deltas,
  });

  /// Whether any cable group quantity changed for this location.
  bool get hasChanges => deltas.any((delta) => delta.state != DiffState.unchanged);
}

/// The change in quantity of one cable group at a location.
class CableQtyDelta {
  final CableQtyGroup group;
  final int originalQty;
  final int currentQty;

  CableQtyDelta({
    required this.group,
    required this.originalQty,
    required this.currentQty,
  });

  DiffState get state {
    if (originalQty == 0 && currentQty > 0) return DiffState.added;
    if (currentQty == 0 && originalQty > 0) return DiffState.deleted;
    if (currentQty != originalQty) return DiffState.changed;
    return DiffState.unchanged;
  }
}
