import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/fixture_mode_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/utils/get_uid.dart';

List<FixtureModel> getMockFixtures() {
  final fixtureTypes = getMockFixtureTypes();

  final defaultFixture = FixtureModel(
    uid: 'default',
    dmxAddress: DMXAddressModel(universe: 1, address: 1),
    mode: FixtureModeModel(name: 'default'),
    dataMulti: '',
    dataPatch: '',
    locationId: '',
    powerMulti: '',
    powerPatch: 0,
    fid: 1,
    type: fixtureTypes['Quantum Wash']!,
  );

  return [
    defaultFixture.copyWith(
      fid: 101,
      uid: getUid(),
      type: fixtureTypes['Quantum Wash'],
    ),
    defaultFixture.copyWith(
      fid: 102,
      uid: getUid(),
      type: fixtureTypes['Quantum Wash'],
    ),
    defaultFixture.copyWith(
      fid: 103,
      uid: getUid(),
      type: fixtureTypes['Quantum Wash'],
    ),
    defaultFixture.copyWith(
      fid: 104,
      uid: getUid(),
      type: fixtureTypes['Quantum Wash'],
    ),
    defaultFixture.copyWith(
      fid: 105,
      uid: getUid(),
      type: fixtureTypes['Sharpy'],
    ),
    defaultFixture.copyWith(
      fid: 106,
      uid: getUid(),
      type: fixtureTypes['Sharpy'],
    ),
    defaultFixture.copyWith(
      fid: 107,
      uid: getUid(),
      type: fixtureTypes['Sharpy'],
    ),
    defaultFixture.copyWith(
      fid: 108,
      uid: getUid(),
      type: fixtureTypes['Sharpy'],
    ),
    defaultFixture.copyWith(
      fid: 109,
      uid: getUid(),
      type: fixtureTypes['Sharpy'],
    ),
    defaultFixture.copyWith(
      fid: 110,
      uid: getUid(),
      type: fixtureTypes['Sharpy'],
    ),
    defaultFixture.copyWith(
      fid: 111,
      uid: getUid(),
      type: fixtureTypes['Sharpy'],
    ),
    defaultFixture.copyWith(
      fid: 112,
      uid: getUid(),
      type: fixtureTypes['Sharpy'],
    ),
    defaultFixture.copyWith(
      fid: 113,
      uid: getUid(),
      type: fixtureTypes['Quantum Wash'],
    ),
    defaultFixture.copyWith(
      fid: 114,
      uid: getUid(),
      type: fixtureTypes['Quantum Wash'],
    ),
    defaultFixture.copyWith(
      fid: 115,
      uid: getUid(),
      type: fixtureTypes['Quantum Wash'],
    ),
    defaultFixture.copyWith(
      fid: 116,
      uid: getUid(),
      type: fixtureTypes['Quantum Wash'],
    ),
  ];
}

Map<String, FixtureTypeModel> getMockFixtureTypes() {
  return {
    'Rush Par': FixtureTypeModel(name: 'Rush Par', uid: 'Rush Par', amps: 2, maxPiggybacks: 4),
    'Blinder': FixtureTypeModel(name: 'Blinder', uid: 'Blinder', amps: 4.2, maxPiggybacks: 4),
    'Patt 2013': FixtureTypeModel(
      name: 'Patt 2013',
      uid: 'Patt 2013',
      amps: 2,
      maxPiggybacks: 3,
    ),
    'Quantum Wash': FixtureTypeModel(
      name: 'Quantum Wash',
      uid: 'Quantum Wash',
      amps: 3.5,
      maxPiggybacks: 1,
    ),
    'Aura XB': FixtureTypeModel(
      name: 'Aura XB',
      uid: 'Aura XB',
      amps: 2,
      maxPiggybacks: 4,
    ),
    'Domino LT': FixtureTypeModel(
      name: 'Domino LT',
      uid: 'Domino LT',
      amps: 9,
      maxPiggybacks: 1,
    ),
    'GLP JDC-1': FixtureTypeModel(
      name: 'GLP JDC-1',
      uid: 'GLP JDC-1',
      amps: 5.2,
      maxPiggybacks: 4,
    ),
    'Strike M': FixtureTypeModel(
      name: 'Strike M',
      uid: 'Strike M',
      amps: 3.3,
      maxPiggybacks: 2,
    ),
    'Mac Viper Profile': FixtureTypeModel(
      name: 'Mac Viper Profile',
      uid: 'Mac Viper Profile',
      amps: 6,
      maxPiggybacks: 1,
    ),
    'Best Boy HP': FixtureTypeModel(
      name: 'Best Boy HP',
      uid: 'Best Boy HP',
      amps: 9.5,
      maxPiggybacks: 1,
    ),
    'Sharpy': FixtureTypeModel(
      name: 'Sharpy',
      uid: 'Sharpy',
      amps: 1,
      maxPiggybacks: 2,
    ),
    'Unico': FixtureTypeModel(
      name: 'Unico',
      uid: 'Unico',
      amps: 8.5,
      maxPiggybacks: 1,
    )
  };
}
