import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/cable_visibility_model.dart';
import 'package:sidekick/redux/models/fixture_geometry_model.dart';
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

  /// Imported GDTF geometry of the fixture's type, when available.
  final FixtureGeometryModel? geometry;

  FixtureViewModel({
    required this.fixture,
    required this.fixtureType,
    this.geometry,
  });
}

class PowerMultiHeaderViewModel {
  final CableType type;
  final String name;

  PowerMultiHeaderViewModel({required this.type, required this.name});
}

class CableViewViewModel {
  final List<NodeElement> elements;
  final List<EdgeElement> edges;
  final List<TrussViewModel> trusses;
  final CableVisibilityModel cableVisibility;
  final void Function(CableVisibilityModel value) onVisibilityChanged;

  CableViewViewModel({
    required this.elements,
    required this.edges,
    required this.trusses,
    required this.cableVisibility,
    required this.onVisibilityChanged,
  });
}

/// A single truss stick, carried as its eight world-space corners (mm).
///
/// The rig viewer projects the corners through its current view and paints
/// their convex hull, so the footprint is correct for any orientation and any
/// viewpoint without the view model knowing which view is selected.
class TrussViewModel {
  final String uid;
  final String name;
  final List<Vector3> corners;

  TrussViewModel({
    required this.uid,
    required this.name,
    required this.corners,
  });
}

sealed class NodeElement {
  /// Position in world space (mm, Z-up), projected per-view by the rig
  /// viewer's layer builders.
  final Vector3 position;

  NodeElement({required this.position});
}

class FixtureElement extends NodeElement {
  final FixtureViewModel fixtureVm;

  FixtureElement({required this.fixtureVm, required super.position});
}

class LocationElement extends NodeElement {
  final String locationId;

  LocationElement({required this.locationId, required super.position});
}

class PowerMultiHeaderElement extends NodeElement {
  final PowerMultiHeaderViewModel powerMultiVm;

  PowerMultiHeaderElement({
    required this.powerMultiVm,
    required super.position,
  });
}

class DataMultiHeaderElement extends NodeElement {
  final String outletName;

  DataMultiHeaderElement({required this.outletName, required super.position});
}

class DataPatchHeaderElement extends NodeElement {
  final String outletName;
  final int universe;

  DataPatchHeaderElement({
    required this.outletName,
    required this.universe,
    required super.position,
  });
}

class TrussBreakElement extends NodeElement {
  TrussBreakElement({required super.position});
}

sealed class EdgeElement {
  final NodeElement fromElement;
  final NodeElement toElement;

  EdgeElement({required this.fromElement, required this.toElement});
}

class CableEdgeElement extends EdgeElement {
  final CableType type;
  final double length;
  final CableRunType runType;

  CableEdgeElement({
    required this.type,
    required this.length,
    required this.runType,
    required super.toElement,
    required super.fromElement,
  });
}

class PsuedoEdgeElement extends EdgeElement {
  PsuedoEdgeElement({required super.toElement, required super.fromElement});
}

class CableLengthBreakpoints {
  static List<double> au10A = [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];

  static List<double> motorMulti = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50];

  static List<double> socapex = [
    2,
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
    50,
  ];

  static List<double> wieland6Way = [
    2,
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
    50,
  ];

  static List<double> dmx = [1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  static List<double> true1 = [0.7, 1, 2, 3, 5, 10, 15];
  static List<double> sneak = [2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
  static List<double> nac3 = [0.5, 1, 2, 3, 5, 10];
}

class CableQtyGroup {
  final CableType type;
  final double length;

  CableQtyGroup({required this.type, required this.length});

  /// Human-readable label for display, combining length and type.
  ///
  /// Header cable types describe a fixed adaptor rather than a run, so their
  /// length is omitted.
  String get label {
    final typeSlug = switch (type) {
      CableType.unknown => throw UnimplementedError(),
      CableType.socapex => 'Soca',
      CableType.wieland6way => '6way',
      CableType.sneak => 'Sneak',
      CableType.dmx => 'DMX',
      CableType.hoist => 'Motor Cable',
      CableType.hoistMulti => 'Motor Multi',
      CableType.au10a => '10A Ext',
      CableType.true1 => 'True1 Ext',
      CableType.socapexToAu10ALampHeader => 'Soca AU10A Header',
      CableType.socapexToTrue1LampHeader => 'Socapex True1 Header',
      CableType.wieland6WayLampHeader => '6way AU10A Header',
      CableType.wieland6WayRackHeader => '6way Rack Header',
      CableType.hoistMultiLampHeader => 'Motor Multi Lamp Header',
      CableType.hoistMultiRackHeader => 'Motor Multi Rack Header',
      CableType.socapexTo6wayAdaptor => 'Soca to 6way Adapter',
      CableType.sneakLampHeader => 'Sneak Lamp Header',
      CableType.sneakRackHeader => 'Sneak Rack Header',
      CableType.nac3Joiner => 'Powercon Joiner',
      CableType.nac3 => 'Powercon',
      CableType.wilco32a => 'Wilco 32a',
      CableType.consoleLoom => 'Console Loom',
      CableType.etherconJoiner => 'Ethercon Joiner',
      CableType.ethercon => 'Ethercon',
    };

    const lengthLessTypes = {
      CableType.socapexToAu10ALampHeader,
      CableType.socapexToTrue1LampHeader,
      CableType.sneakLampHeader,
      CableType.sneakRackHeader,
      CableType.socapexTo6wayAdaptor,
      CableType.hoistMultiRackHeader,
      CableType.hoistMultiLampHeader,
      CableType.wieland6WayLampHeader,
      CableType.wieland6WayRackHeader,
      CableType.etherconJoiner,
      CableType.nac3Joiner,
    };

    if (lengthLessTypes.contains(type)) {
      return typeSlug;
    }

    final lengthText = length.remainder(1) == 0
        ? '${length.toStringAsFixed(0)}m'
        : '${length.toStringAsFixed(1)}m';

    return '$lengthText $typeSlug';
  }

  static List<CableQtyGroup> socapexGroups = [
    CableQtyGroup(type: CableType.socapexToAu10ALampHeader, length: 0),
    CableQtyGroup(type: CableType.socapexToTrue1LampHeader, length: 0),
    ..._buildQtyGroups(CableLengthBreakpoints.socapex, CableType.socapex),
    CableQtyGroup(type: CableType.socapexTo6wayAdaptor, length: 0),
  ];
  static List<CableQtyGroup> wieland6WayGroups = [
    CableQtyGroup(type: CableType.wieland6WayLampHeader, length: 0),
    CableQtyGroup(type: CableType.wieland6WayRackHeader, length: 0),
    ..._buildQtyGroups(
      CableLengthBreakpoints.wieland6Way,
      CableType.wieland6way,
    ),
  ];

  static List<CableQtyGroup> hoistMultiGroups = [
    CableQtyGroup(type: CableType.hoistMultiLampHeader, length: 0),
    CableQtyGroup(type: CableType.hoistMultiRackHeader, length: 0),
    ..._buildQtyGroups(CableLengthBreakpoints.motorMulti, CableType.hoistMulti),
  ];

  static List<CableQtyGroup> motorCableGroups = [
    ..._buildQtyGroups(CableLengthBreakpoints.motorMulti, CableType.hoist),
  ];

  static List<CableQtyGroup> dmxGroups = [
    CableQtyGroup(type: CableType.sneakLampHeader, length: 0),
    CableQtyGroup(type: CableType.sneakRackHeader, length: 0),
    ..._buildQtyGroups(CableLengthBreakpoints.dmx, CableType.dmx),
  ];

  static List<CableQtyGroup> au10AGroups = _buildQtyGroups(
    CableLengthBreakpoints.au10A,
    CableType.au10a,
  );

  static List<CableQtyGroup> true1Groups = _buildQtyGroups(
    CableLengthBreakpoints.true1,
    CableType.true1,
  );

  static List<CableQtyGroup> nac3Groups = [
    CableQtyGroup(type: CableType.nac3Joiner, length: 0),
    ..._buildQtyGroups(CableLengthBreakpoints.nac3, CableType.nac3),
  ];

  static List<CableQtyGroup> wilcoGroups = [
    ..._buildQtyGroups(CableLengthBreakpoints.socapex, CableType.wilco32a),
  ];

  static List<CableQtyGroup> consoleLoomGroups = [
    CableQtyGroup(type: CableType.consoleLoom, length: 5),
    CableQtyGroup(type: CableType.consoleLoom, length: 10),
  ];

  static List<CableQtyGroup> etherconGroups = [
    CableQtyGroup(type: CableType.etherconJoiner, length: 0),
    ..._buildQtyGroups(CableLengthBreakpoints.sneak, CableType.sneak),
  ];

  static List<CableQtyGroup> allGroups = [
    ...socapexGroups,
    ...wieland6WayGroups,
    ...hoistMultiGroups,
    ...motorCableGroups,
    ...au10AGroups,
    ...dmxGroups,
    ...true1Groups,
    ...etherconGroups,
    ...wilcoGroups,
    ...nac3Groups,
  ];

  static List<CableQtyGroup> _buildQtyGroups(
    List<double> lengths,
    CableType type,
  ) {
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
