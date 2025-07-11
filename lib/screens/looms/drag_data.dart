import 'package:sidekick/view_models/looms_view_model.dart';

abstract class DragData {}

class OutletDragData extends DragData {
  final Set<OutletViewModel> outletVms;

  OutletDragData({required this.outletVms});
}

class CableDragData extends DragData {
  final Set<String> cableIds;

  CableDragData({required this.cableIds});
}
