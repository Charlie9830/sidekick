// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sidekick/cable_graph/cable_graph.dart';

class CableVisibilityModel {
  final Set<CableRunType> powerState;
  final Set<CableRunType> dataState;

  CableVisibilityModel({
    required this.powerState,
    required this.dataState,
  });

  const CableVisibilityModel.all()
      : powerState = const {
          CableRunType.fixtureRun,
          CableRunType.homeRun,
          CableRunType.link,
        },
        dataState = const {
          CableRunType.fixtureRun,
          CableRunType.homeRun,
          CableRunType.link,
        };

  CableVisibilityModel copyWith({
    Set<CableRunType>? powerState,
    Set<CableRunType>? dataState,
  }) {
    return CableVisibilityModel(
      powerState: powerState ?? this.powerState,
      dataState: dataState ?? this.dataState,
    );
  }
}
