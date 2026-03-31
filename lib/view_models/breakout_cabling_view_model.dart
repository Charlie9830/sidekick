import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

class BreakoutCablingViewModel {
  final String selectedLocationId;
  final List<LocationViewModel> locationVms;
  final Map<String, FixtureViewModel> locationFixtureVms;
  final Map<String, FixtureModel> fixtureMap;

  BreakoutCablingViewModel({
    required this.locationVms,
    required this.locationFixtureVms,
    required this.selectedLocationId,
    required this.fixtureMap,
  });
}

class LocationViewModel {
  final LocationModel location;
  final void Function() onSelect;

  LocationViewModel({
    required this.location,
    required this.onSelect,
  });
}

class FixtureViewModel implements ModelCollectionMember {
  @override
  String get uid => fixture.uid;

  final FixtureModel fixture;
  final FixtureTypeModel fixtureType;

  FixtureViewModel({required this.fixture, required this.fixtureType});
}
