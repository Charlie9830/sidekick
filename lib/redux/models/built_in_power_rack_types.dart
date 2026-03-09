import 'package:sidekick/redux/models/power_rack_type_model.dart';

class BuiltInPowerRackTypes {
  static const Map<String, PowerRackTypeModel> types = {
    '96way': PowerRackTypeModel(
      uid: '96way',
      name: '96way',
      ways: 96,
      multiWayDivisor: 6,
    ),
    'pwp12': PowerRackTypeModel(
      uid: 'pwp12',
      name: 'PWP-12',
      ways: 12,
      multiWayDivisor: 6,
    ),
  };
}
