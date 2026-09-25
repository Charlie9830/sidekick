import 'package:sidekick/redux/models/cable_model.dart';

/// The kind of cable that arrives at a location's lamp end, which decides the
/// header (and so the tails) that fixture runs start from.
enum HeaderKind {
  socapex(CableType.socapex, {CableType.au10a, CableType.true1}),
  wieland6way(CableType.wieland6way, {CableType.au10a}),
  sneak(CableType.sneak, {CableType.dmx}),

  /// A DMX cable run on its own: no header, the cable itself is the tail.
  straightDmx(CableType.dmx, {CableType.dmx});

  /// The cable that arrives at the header.
  final CableType arrivingCable;

  /// The cables a header of this kind provides to fixture runs.
  final Set<CableType> tails;

  const HeaderKind(this.arrivingCable, this.tails);

  /// The tail that feeds fixture runs from this header.
  ///
  /// A header has one type of tail, so when it offers several it only uses a
  /// specialised one (e.g. True1 on Socapex) if every fixture it feeds takes
  /// it; otherwise it uses its first (most general) tail.
  CableType tailFor(Iterable<CableType> fixtureInputs) {
    final inputs = fixtureInputs.toSet();
    return inputs.length == 1 && tails.contains(inputs.single)
        ? inputs.single
        : tails.first;
  }

  /// The lamp-end header counted for this header with the given [tail], or
  /// null when there is none (a straight DMX run).
  CableType? lampHeaderFor(CableType tail) => switch (this) {
    socapex when tail == CableType.true1 => CableType.socapexToTrue1LampHeader,
    socapex => CableType.socapexToAu10ALampHeader,
    wieland6way => CableType.wieland6WayLampHeader,
    sneak => CableType.sneakLampHeader,
    straightDmx => null,
  };

  /// The power header kind arriving on [cableType], or null when it is not a
  /// power multicore.
  static HeaderKind? forPowerCable(CableType cableType) => switch (cableType) {
    CableType.socapex => socapex,
    CableType.wieland6way => wieland6way,
    _ => null,
  };
}

/// How a data patch arrives at its location.
class DataHeader {
  final HeaderKind kind;

  /// The data multi outlet whose sneak carries this patch, or empty when the
  /// patch is run as [HeaderKind.straightDmx].
  final String parentMultiOutletId;

  const DataHeader.straight()
    : kind = HeaderKind.straightDmx,
      parentMultiOutletId = '';

  const DataHeader.inSneak(this.parentMultiOutletId) : kind = HeaderKind.sneak;
}

/// Works out each outlet's header from the last cable in its loom chain.
///
/// An outlet's feeder cable leaves the rack and may be extended through
/// further looms; each extension points at the cable it extends via
/// [CableModel.upstreamId]. Only the last cable in that chain reaches the
/// fixtures, so it alone decides the header.
class HeaderResolver {
  final Map<String, CableModel> _cables;
  final CableType _defaultPowerMulti;
  final Map<String, CableModel> _feederByOutletId;
  final Map<String, CableModel> _extensionByUpstreamId;

  /// [defaultPowerMulti] is used for power outlets with no cables yet.
  HeaderResolver(
    Map<String, CableModel> cables, {
    required CableType defaultPowerMulti,
  }) : _cables = cables,
       _defaultPowerMulti = defaultPowerMulti,
       _feederByOutletId = _firstBy(
         cables.values.where(_isFeeder),
         (cable) => cable.outletId,
       ),
       _extensionByUpstreamId = _firstBy(
         cables.values.where((cable) => cable.upstreamId.isNotEmpty),
         (cable) => cable.upstreamId,
       );

  /// The header a power multi outlet's fixture runs start from.
  HeaderKind powerHeaderFor(String outletId) {
    final lastCable = _lastCableFrom(outletId);

    return (lastCable == null
            ? null
            : HeaderKind.forPowerCable(lastCable.type)) ??
        HeaderKind.forPowerCable(_defaultPowerMulti) ??
        HeaderKind.socapex;
  }

  /// How a data patch outlet arrives: inside a sneak, or as a straight DMX
  /// run.
  DataHeader dataHeaderFor(String outletId) {
    final parent = _cables[_lastCableFrom(outletId)?.parentMultiId];

    return parent?.type == CableType.sneak
        ? DataHeader.inSneak(parent!.outletId)
        : const DataHeader.straight();
  }

  /// Follows [outletId]'s feeder downstream to the last cable in its chain.
  CableModel? _lastCableFrom(String outletId) {
    // Cannot loop: every cable has one upstream and the feeder has none, so a
    // chain starting at the feeder never revisits a cable.
    var cable = _feederByOutletId[outletId];
    while (cable != null && _extensionByUpstreamId[cable.uid] != null) {
      cable = _extensionByUpstreamId[cable.uid];
    }
    return cable;
  }

  /// A cable leaving the rack: not an extension, and belonging to an outlet.
  ///
  /// Multi children are included, since a data patch's own cable is the child
  /// of its sneak.
  static bool _isFeeder(CableModel cable) =>
      cable.upstreamId.isEmpty && cable.outletId.isNotEmpty;

  /// Indexes [cables] by [key], keeping the first cable when keys collide.
  static Map<String, CableModel> _firstBy(
    Iterable<CableModel> cables,
    String Function(CableModel cable) key,
  ) {
    final result = <String, CableModel>{};
    for (final cable in cables) {
      result.putIfAbsent(key(cable), () => cable);
    }
    return result;
  }
}
