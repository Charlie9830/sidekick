import 'package:sidekick/redux/models/cable_model.dart';

(String primaryLocationId, Set<String> secondaryLocationId)
    selectPrimaryAndSecondaryLocationIds(List<CableModel> cables) {
  if (cables.isEmpty) {
    throw const FormatException(
        '[cables] is empty. [cables] must have at least 1 element');
  }

  final primaryLocationId = cables.first.locationId;

  final secondaryLocationIds = cables.length > 1
      ? cables
          .sublist(1)
          .map((cable) => cable.locationId)
          .where((locationId) => locationId != primaryLocationId)
          .toSet()
      : <String>{};
  return (primaryLocationId, secondaryLocationIds);
}
