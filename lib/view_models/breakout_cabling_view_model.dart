import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

class BreakoutCablingViewModel {
  final String selectedLocationId;
  final List<LocationViewModel> locationVms;
  final Map<String, FixtureViewModel> locationFixtureVms;
  final Map<String, FixtureModel> fixtureMap;
  final CableViewViewModel cableViewVm;

  BreakoutCablingViewModel({
    required this.locationVms,
    required this.locationFixtureVms,
    required this.selectedLocationId,
    required this.fixtureMap,
    required this.cableViewVm,
  });
}

class LocationViewModel {
  final LocationModel location;
  final void Function() onSelect;

  LocationViewModel({
    required this.location,
    required this.onSelect,
  });
}

class FixtureViewModel implements ModelCollectionMember {
  @override
  String get uid => fixture.uid;

  final FixtureModel fixture;
  final FixtureTypeModel fixtureType;

  FixtureViewModel({required this.fixture, required this.fixtureType});
}

class PowerMultiHeaderViewModel {
  final CableType type;
  final String name;

  PowerMultiHeaderViewModel({
    required this.type,
    required this.name,
  });
}

class CableViewViewModel {
  final List<NodeElement> elements;
  final List<EdgeElement> edges;

  CableViewViewModel({
    required this.elements,
    required this.edges,
  });
}

sealed class NodeElement {
  final double screenX;
  final double screenY;

  NodeElement({
    required this.screenX,
    required this.screenY,
  });
}

class FixtureElement extends NodeElement {
  final FixtureViewModel fixtureVm;

  FixtureElement({
    required this.fixtureVm,
  }) : super(
          screenX: fixtureVm.fixture.screenX,
          screenY: fixtureVm.fixture.screenY,
        );
}

class LocationElement extends NodeElement {
  final String locationId;

  LocationElement({
    required this.locationId,
    required super.screenX,
    required super.screenY,
  });
}

class PowerMultiHeaderElement extends NodeElement {
  final PowerMultiHeaderViewModel powerMultiVm;

  PowerMultiHeaderElement({
    required this.powerMultiVm,
    required super.screenX,
    required super.screenY,
  });
}

sealed class EdgeElement {
  final NodeElement sourceElement;
  final NodeElement destinationElement;

  EdgeElement({
    required this.sourceElement,
    required this.destinationElement,
  });
}

class CableEdgeElement extends EdgeElement {
  final CableType type;
  final double length;
  final CableRunType runType;

  CableEdgeElement(
      {required this.type,
      required this.length,
      required this.runType,
      required super.destinationElement,
      required super.sourceElement});
}
