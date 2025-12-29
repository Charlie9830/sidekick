import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/diffing/diff_comparable.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';

class LocationHeaderRow extends StatelessWidget {
  final LocationModel location;
  final Widget trailing;
  final PropertyDeltaSet? deltas;

  const LocationHeaderRow(
      {Key? key,
      required this.location,
      this.deltas,
      this.trailing = const SizedBox(width: 0)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 24.0, left: 8.0, top: 24, right: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on,
            color: Colors.gray,
          ),
          const SizedBox(width: 8),
          DiffStateOverlay(
              diff: deltas?.lookup(PropertyDeltaName.locationName),
              child: Text(location.name,
                  style: Theme.of(context).typography.xLarge)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
