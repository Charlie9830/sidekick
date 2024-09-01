import 'package:sidekick/redux/models/loom_model.dart';

class LoomRowViewModel {
  final LoomModel loom;
  final String locationName;

  LoomRowViewModel({
    required this.loom,
    required this.locationName,
  });
}
