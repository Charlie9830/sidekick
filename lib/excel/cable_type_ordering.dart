import 'package:sidekick/classes/cable_family.dart';
import 'package:sidekick/redux/models/cable_model.dart';

int parentCableTypeComparator(CableFamily a, CableFamily b) {
  return CableModel.compareByType(a.parent, b.parent);
}
