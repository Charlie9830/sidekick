import 'package:sidekick/redux/models/power_system_model.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class PowerSystemViewModel {
  final PowerSystemModel system;
  final List<PowerFeedViewModel> childFeeds;

  PowerSystemViewModel({
    required this.system,
    required this.childFeeds,
  });
}
