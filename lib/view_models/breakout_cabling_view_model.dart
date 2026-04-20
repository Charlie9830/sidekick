import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/cable_visibility_model.dart';
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
  final Map<CableQtyGroup, int> cableQtys;

  LocationViewModel({
    required this.location,
    required this.onSelect,
    required this.cableQtys,
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
  final CableVisibilityModel cableVisibility;
  final void Function(CableVisibilityModel value) onVisibilityChanged;

  CableViewViewModel({
    required this.elements,
    required this.edges,
    required this.cableVisibility,
    required this.onVisibilityChanged,
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

class DataMultiHeaderElement extends NodeElement {
  final String outletName;

  DataMultiHeaderElement({
    required this.outletName,
    required super.screenX,
    required super.screenY,
  });
}

class DataPatchHeaderElement extends NodeElement {
  final String outletName;
  final int universe;

  DataPatchHeaderElement({
    required this.outletName,
    required this.universe,
    required super.screenX,
    required super.screenY,
  });
}

sealed class EdgeElement {
  final NodeElement fromElement;
  final NodeElement toElement;

  EdgeElement({
    required this.fromElement,
    required this.toElement,
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
      required super.toElement,
      required super.fromElement});
}

class PsuedoEdgeElement extends EdgeElement {
  PsuedoEdgeElement({required super.toElement, required super.fromElement});
}

class CableLengthBreakpoints {
  static List<double> au10A = [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  static List<double> socapex = [
    3,
    5,
    7.5,
    10,
    12.5,
    15,
    17.5,
    20,
    25,
    30,
    35,
    40,
    45,
    50
  ];

  static List<double> wieland6Way = [
    3,
    5,
    7.5,
    10,
    12.5,
    15,
    17.5,
    20,
    25,
    30,
    35,
    40,
    45,
    50
  ];

  static List<double> dmx = [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  static List<double> true1 = [0.7, 1, 2, 3, 5, 10, 15];
  static List<double> sneak = [2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
}

class CableQtyGroup {
  final CableType type;
  final double length;

  CableQtyGroup({
    required this.type,
    required this.length,
  });

  static List<CableQtyGroup> socapexGroups = [
    CableQtyGroup(type: CableType.socapexToAu10ALampHeader, length: 0),
    CableQtyGroup(type: CableType.socapexToTrue1LampHeader, length: 0),
    ..._buildQtyGroups(CableLengthBreakpoints.socapex, CableType.socapex)
  ];
  static List<CableQtyGroup> wieland6WayGroups = [
    CableQtyGroup(type: CableType.wieland6WayLampHeader, length: 0),
    ..._buildQtyGroups(
        CableLengthBreakpoints.wieland6Way, CableType.wieland6way)
  ];
  static List<CableQtyGroup> dmxGroups = [
    CableQtyGroup(type: CableType.sneakLampHeader, length: 0),
    ..._buildQtyGroups(CableLengthBreakpoints.dmx, CableType.dmx)
  ];
  static List<CableQtyGroup> au10AGroups =
      _buildQtyGroups(CableLengthBreakpoints.au10A, CableType.au10a);
  static List<CableQtyGroup> true1Groups =
      _buildQtyGroups(CableLengthBreakpoints.true1, CableType.true1);

  static List<CableQtyGroup> sneakGroups =
      _buildQtyGroups(CableLengthBreakpoints.sneak, CableType.sneak);

  static List<CableQtyGroup> allGroups = [
    ...socapexGroups,
    ...wieland6WayGroups,
    ...dmxGroups,
    ...au10AGroups,
    ...true1Groups,
    ...sneakGroups,
  ];

  static List<CableQtyGroup> _buildQtyGroups(
      List<double> lengths, CableType type) {
    return lengths
        .map((length) => CableQtyGroup(length: length, type: type))
        .toList();
  }

  @override
  bool operator ==(Object other) {
    return other is CableQtyGroup &&
        other.type == type &&
        other.length == length;
  }

  @override
  int get hashCode => type.hashCode ^ length.hashCode;
}
