import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/cable_graph/cabling/header_resolver.dart';
import 'package:sidekick/redux/models/cable_model.dart';

Map<String, CableModel> _cables(List<CableModel> cables) => {
  for (final cable in cables) cable.uid: cable,
};

HeaderResolver _resolver(
  List<CableModel> cables, {
  CableType defaultPowerMulti = CableType.socapex,
}) => HeaderResolver(_cables(cables), defaultPowerMulti: defaultPowerMulti);

void main() {
  group('power headers', () {
    test('a lone feeder decides the header', () {
      final resolver = _resolver([
        CableModel(uid: 'c1', type: CableType.wieland6way, outletId: 'pm'),
      ]);

      expect(resolver.powerHeaderFor('pm'), HeaderKind.wieland6way);
    });

    test('the last cable in an extension chain wins', () {
      final resolver = _resolver([
        CableModel(uid: 'feeder', type: CableType.socapex, outletId: 'pm'),
        CableModel(
          uid: 'ext1',
          type: CableType.socapex,
          outletId: 'pm',
          upstreamId: 'feeder',
        ),
        CableModel(
          uid: 'ext2',
          type: CableType.wieland6way,
          outletId: 'pm',
          upstreamId: 'ext1',
        ),
      ]);

      expect(resolver.powerHeaderFor('pm'), HeaderKind.wieland6way);
    });

    test('outlets without cables use the default power multi', () {
      expect(
        _resolver(
          [],
          defaultPowerMulti: CableType.wieland6way,
        ).powerHeaderFor('pm'),
        HeaderKind.wieland6way,
      );
      expect(_resolver([]).powerHeaderFor('pm'), HeaderKind.socapex);
    });

    test('a non-multicore default falls back to Socapex', () {
      final resolver = _resolver([], defaultPowerMulti: CableType.unknown);

      expect(resolver.powerHeaderFor('pm'), HeaderKind.socapex);
    });
  });

  group('data headers', () {
    final sneak = CableModel(uid: 's1', type: CableType.sneak, outletId: 'dm');
    final dmxInSneak = CableModel(
      uid: 'd1',
      type: CableType.dmx,
      outletId: 'dp',
      parentMultiId: 's1',
    );

    test('a DMX line inside a sneak arrives at a sneak header', () {
      final header = _resolver([sneak, dmxInSneak]).dataHeaderFor('dp');

      expect(header.kind, HeaderKind.sneak);
      expect(header.parentMultiOutletId, 'dm');
    });

    test('an extended sneak still carries its DMX lines', () {
      final header = _resolver([
        sneak,
        dmxInSneak,
        CableModel(
          uid: 's2',
          type: CableType.sneak,
          outletId: 'dm',
          upstreamId: 's1',
        ),
        CableModel(
          uid: 'd2',
          type: CableType.dmx,
          outletId: 'dp',
          upstreamId: 'd1',
          parentMultiId: 's2',
        ),
      ]).dataHeaderFor('dp');

      expect(header.kind, HeaderKind.sneak);
      expect(header.parentMultiOutletId, 'dm');
    });

    test('a DMX line extended out of its sneak arrives straight', () {
      final header = _resolver([
        sneak,
        dmxInSneak,
        CableModel(
          uid: 'd2',
          type: CableType.dmx,
          outletId: 'dp',
          upstreamId: 'd1',
        ),
      ]).dataHeaderFor('dp');

      expect(header.kind, HeaderKind.straightDmx);
      expect(header.parentMultiOutletId, isEmpty);
    });

    test('patches without cables arrive straight', () {
      expect(_resolver([]).dataHeaderFor('dp').kind, HeaderKind.straightDmx);
    });
  });
}
