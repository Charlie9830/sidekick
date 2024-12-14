import 'package:sidekick/classes/folded_cable.dart';
import 'package:sidekick/redux/models/cable_model.dart';

int parentCableTypeComparator(FoldedCable a, FoldedCable b) {
  return CableModel.compareByType(a.cable, b.cable);
}
