import 'package:mvr/mvr.dart';

import 'package:sidekick/cable_graph/cabling/cable_stock.dart';
import 'package:sidekick/redux/models/cable_model.dart';

/// The cable that plugs into each connector, keyed by normalised connector
/// name (see [_normalise]).
///
/// Covers both GDTF Annex D predefined connectors and the custom names
/// manufacturers write in their place. To support a new connector, add a row.
final Map<String, CableType> _cableTypeByConnector = {
  'au10a': CableType.au10a,
  'powercontrue1': CableType.true1,
  'powercontrue1top': CableType.true1,
  'true1': CableType.true1,
  'nac3fca': CableType.nac3,
  'nac3fcb': CableType.nac3,
  'powercon': CableType.nac3,
  'xlr5': CableType.dmx,
  'xlr3': CableType.dmx,
};

/// Lowercases [connectorName] and strips spaces, hyphens and underscores, so
/// "powerCON TRUE1", "PowerconTRUE1" and "powercon_true1" all match.
String _normalise(String connectorName) =>
    connectorName.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');

/// The cable that plugs into [connector], or null when it is unknown.
CableType? cableTypeForConnector(GDTFConnectorType? connector) =>
    connector == null
    ? null
    : _cableTypeByConnector[_normalise(connector.xmlValue)];

/// The cables a fixture's [signal] connectors can take: its fallback cable
/// plus every cable in the connector table carrying that signal.
///
/// These are the choices offered when overriding a fixture type's cabling.
List<CableType> fixtureCableTypes(CableSignal signal) => {
  fallbackCableType(signal),
  ..._cableTypeByConnector.values.where((type) => type.signal == signal),
}.toList();

/// The adaptor that lets a header tail of one cable type feed a fixture input
/// of another, keyed by `(tail, input)`. To support a new adaptor, add a row.
final Map<(CableType, CableType), CableType> _adaptors = {
  (CableType.au10a, CableType.true1): CableType.au10aToTrue1Adaptor,
  (CableType.au10a, CableType.nac3): CableType.au10aToNac3Adaptor,
};

/// The adaptor needed to plug a [tail] cable into an [input] connector, or
/// null when they already fit or no adaptor is stocked.
CableType? adaptorFor({required CableType tail, required CableType input}) =>
    tail == input ? null : _adaptors[(tail, input)];

/// The cable signal a GDTF signal type is carried on, or null for signals
/// breakout cabling does not handle (e.g. Ethernet).
CableSignal? cableSignalFor(GDTFSignalType? signal) => switch (signal) {
  GDTFPredefinedSignalType.power => CableSignal.power,
  GDTFPredefinedSignalType.dmx512 => CableSignal.data,
  _ => null,
};

/// The cable used when a connector is missing, unknown or overridden away.
///
/// Every fixture can take an AU10A power input and output, since AU10A plugs
/// can be paired, and 5-pin DMX for data.
CableType fallbackCableType(CableSignal signal) => switch (signal) {
  CableSignal.power => CableType.au10a,
  CableSignal.data => CableType.dmx,
  CableSignal.network || CableSignal.hoist || CableSignal.none =>
    throw ArgumentError.value(signal, 'signal', 'No fixture cable fallback'),
};
