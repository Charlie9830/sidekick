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

class CableViewViewModel {
  final List<NodeElement> nodes;
  final List<EdgeElement> edges;

  CableViewViewModel({
    required this.nodes,
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

  CableEdgeElement(
      {required this.type,
      required this.length,
      required super.destinationElement,
      required super.sourceElement});
}
