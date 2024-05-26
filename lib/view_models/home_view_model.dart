import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

class HomeViewModel {
  final Map<String, FixtureModel> fixtures;
  final Map<String, LocationModel> locations;
  final Set<String> selectedFixtureIds;
  final void Function() onAppInitialize;
  final void Function(Set<String> ids) onSelectedFixturesChanged;
  final void Function() onSetSequenceButtonPressed;

  HomeViewModel({
    required this.fixtures,
    required this.locations,
    required this.onAppInitialize,
    required this.selectedFixtureIds,
    required this.onSelectedFixturesChanged,
    required this.onSetSequenceButtonPressed,
  });
}
