import 'package:sidekick/redux/models/data_rack_type_model.dart';

class BuiltInDataRackTypes {
  static const Map<String, DataRackTypeModel> types = {
    'hydra_x3_active': DataRackTypeModel(
        uid: 'hydra_x3_active',
        name: 'Hydra',
        outletCount: 72,
        dividers: {
          3: 1,
          7: 1,
          11: 1,
          15: 1,
          19: 1,
          23: 2,
          27: 1,
          31: 1,
          35: 1,
          39: 1,
          43: 1,
          47: 2,
        }),
    'ma2_permanent_rack': DataRackTypeModel(
      uid: 'ma2_permanent_rack',
      name: 'Permanent MA2 NPU Rack',
      outletCount: 40,
      dividers: {},
    ),
    'elc_8_way': DataRackTypeModel(
        uid: 'elc_8_way', name: 'ELC Node', outletCount: 8, dividers: {}),
  };
}
