import 'package:sidekick/enums.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/cable_visibility_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';
import 'package:sidekick/redux/models/outlet.dart';

class SetBreakoutCableVisibilityState {
  final CableVisibilityModel value;

  SetBreakoutCableVisibilityState(this.value);
}

class SetBreakoutCablingLocationId {
  final String value;

  SetBreakoutCablingLocationId(this.value);
}

class UpdateLoomName {
  final String uid;
  final String value;

  UpdateLoomName(this.uid, this.value);
}

class SetLoomStock {
  final Map<String, LoomStockModel> value;

  SetLoomStock(this.value);
}

class SetLoomsDraggingState {
  final LoomsDraggingState value;

  SetLoomsDraggingState(this.value);
}

class SetSelectedLoomOutlets {
  final Set<String> value;

  SetSelectedLoomOutlets(this.value);
}

class SetDefaultPowerMulti {
  final CableType value;

  SetDefaultPowerMulti(this.value);
}

class UpdateCableLength {
  final String uid;
  final String newLength;

  UpdateCableLength(this.uid, this.newLength);
}

class UpdateCablesAndDataMultis {
  final Map<String, CableModel> cables;
  final Map<String, DataMultiModel> dataMultis;

  UpdateCablesAndDataMultis(this.cables, this.dataMultis);
}

class ToggleCableDropperStateByLoom {
  final String loomId;

  ToggleCableDropperStateByLoom(this.loomId);
}

class SetCablesAndLooms {
  final Map<String, CableModel> cables;
  final Map<String, LoomModel> looms;

  SetCablesAndLooms(this.cables, this.looms);
}

class SetIsAvailabilityDrawerOpen {
  final bool value;

  SetIsAvailabilityDrawerOpen(this.value);
}

class UpdateCableNote {
  final String id;
  final String value;

  UpdateCableNote(this.id, this.value);
}

class UpdateLoomLength {
  final String id;
  final String newValue;

  UpdateLoomLength(this.id, this.newValue);
}

class SetCables {
  final Map<String, CableModel> cables;

  SetCables(this.cables);
}

class SetSelectedCableIds {
  final Set<String> ids;

  SetSelectedCableIds(this.ids);
}

class SetLooms {
  final Map<String, LoomModel> looms;

  SetLooms(this.looms);
}
