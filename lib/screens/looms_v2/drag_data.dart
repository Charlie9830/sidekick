import 'package:sidekick/view_models/looms_v2_view_model.dart';

abstract class DragData {}

class OutletDragData extends DragData {
  final Set<OutletViewModel> outletVms;

  OutletDragData({required this.outletVms});
}
