import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

class HomeViewModel {
  final Map<String, FixtureModel> fixtures;
  final Map<String, LocationModel> locations;
  final void Function() onAppInitialize;

  HomeViewModel({
    required this.fixtures,
    required this.locations,
    required this.onAppInitialize,
  });
}
