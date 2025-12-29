import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/screens/power_patch/location_header_trailer.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';
import 'package:sidekick/widgets/location_header_row.dart';

class LocationRow extends StatelessWidget {
  final LocationRowViewModel vm;
  final PropertyDeltaSet? deltas;
  const LocationRow({
    super.key,
    required this.vm,
    this.deltas,
  });

  @override
  Widget build(BuildContext context) {
    return LocationHeaderRow(
      key: Key(vm.location.uid),
      location: vm.location,
      deltas: deltas,
      trailing: LocationHeaderTrailer(
        multiCount: vm.multiCount,
        deltas: deltas,
        onLocationSettingsButtonPressed: vm.onSettingsButtonPressed,
        hasOverrides: vm.location.overrides.hasOverrides,
      ),
    );
  }
}
