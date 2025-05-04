import 'package:sidekick/view_models/fixture_table_view_model.dart';

class IncomingFixtureItemViewModel {
  FixtureViewModel? incomingFixture;
  FixtureViewModel? existingFixture;

  IncomingFixtureItemViewModel({
    this.incomingFixture,
    this.existingFixture,
  });
}
