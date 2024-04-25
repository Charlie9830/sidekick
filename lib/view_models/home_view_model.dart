import 'package:sidekick/redux/models/fixture_model.dart';

class HomeViewModel {
  final Map<String, FixtureModel> fixtures;
  final void Function() onAppInitialize;

  HomeViewModel({
    required this.fixtures,
    required this.onAppInitialize,
  });
}
