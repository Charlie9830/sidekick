import 'package:sidekick/classes/folded_cable.dart';
import 'package:sidekick/redux/models/cable_model.dart';

const _ranking = {
  CableType.socapex: 0,
  CableType.wieland6way: 1,
  CableType.sneak: 2,
  CableType.dmx: 3,
  CableType.unknown: 4,
};

int cableTypeComparator(CableModel a, CableModel b) {
  return _ranking[a.type]! - _ranking[b.type]!;
}

int parentCableTypeComparator(FoldedCable a, FoldedCable b) {
  return cableTypeComparator(a.cable, b.cable);
}
