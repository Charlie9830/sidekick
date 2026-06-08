import 'dart:io';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/outlet.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/serialization/deserialize_project_file.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

void runAnalysis() async {
  final projectFileDirectory = await getDirectoryPath();

  if (projectFileDirectory == null) {
    return;
  }

  final directory = Directory(projectFileDirectory);
  final phaseFiles = <File>[];

  await for (final file
      in directory.list().where((file) => file.path.endsWith('.phase'))) {
    if (file is File) {
      phaseFiles.add(file);
    }
  }

  final deserializationRequests =
      phaseFiles.map((file) => deserializeProjectFile(file.path));

  final requests = await Future.wait(deserializationRequests);

  final states = Map<String, FixtureState>.fromEntries(requests.map((project) =>
      MapEntry(project.metadata.projectName, project.toFixtureState())));

  _runOutletAnalysis(states, projectFileDirectory);
}

List<_LocationRequirments> _calculateLocationRequirments(FixtureState state) {
  final powerMultiOutletsByLocationId = state.powerMultiOutlets.values
      .groupListsBy((outlet) => outlet.locationId);
  final dataPatchOutletsByLocationId =
      state.dataPatches.values.groupListsBy((outlet) => outlet.locationId);

  return state.locations.values
      .map((location) => _LocationRequirments(
          locationName: location.name,
          activePowerLoomCount:
              powerMultiOutletsByLocationId[location.uid]?.length ?? 0,
          activeUniverses:
              dataPatchOutletsByLocationId[location.uid]?.length ?? 0))
      .toList();
}

List<_LoomData> _analyzeLoomUtilization(FixtureState state) {
  final cablesByLoomId =
      state.cables.values.groupListsBy((cable) => cable.loomId);

  return state.looms.values.map((loom) {
    final childCables = cablesByLoomId[loom.uid] ?? [];

    return _LoomData(
      predominantCableClass: _calculatePredominantCableClass(childCables),
      isPermanent: loom.type.permanentComposition.isNotEmpty,
      activePowerWays: childCables
          .where((cable) => _isPowerWay(cable.type) && cable.isSpare == false)
          .length,
      sparePowerWays: childCables
          .where((cable) => _isPowerWay(cable.type) && cable.isSpare == true)
          .length,
      activeDmxWays: childCables
          .where(
              (cable) => cable.type == CableType.dmx && cable.isSpare == false)
          .length,
      spareDmxWays: childCables
          .where(
              (cable) => cable.type == CableType.dmx && cable.isSpare == true)
          .length,
      spareSneakWays: childCables
          .where(
              (cable) => cable.type == CableType.sneak && cable.isSpare == true)
          .length,
      activeSneakWays: childCables
          .where((cable) =>
              cable.type == CableType.sneak && cable.isSpare == false)
          .length,
    );
  }).toList();
}

CableClass _calculatePredominantCableClass(List<CableModel> cables) {
  final cablesByClass = cables.groupListsBy((cable) => cable.cableClass);
  if (cablesByClass.isEmpty) {
    return CableClass.none;
  }

  return cablesByClass.keys
          .toList()
          .sorted((a, b) =>
              cablesByClass[a]?.length ?? 0 - (cablesByClass[b]?.length ?? 0))
          .firstOrNull ??
      CableClass.none;
}

bool _isPowerWay(CableType type) {
  return switch (type) {
    CableType.socapex || CableType.wieland6way => true,
    _ => false,
  };
}

class _LoomData {
  final bool isPermanent;
  final int activePowerWays;
  final int sparePowerWays;
  final int activeDmxWays;
  final int spareDmxWays;
  final int activeSneakWays;
  final int spareSneakWays;
  final CableClass predominantCableClass;

  String get combinedWaysSlug =>
      '${activePowerWays + sparePowerWays}p ${activeSneakWays + spareSneakWays}s ${activeDmxWays + spareDmxWays}d';

  _LoomData({
    required this.predominantCableClass,
    required this.isPermanent,
    required this.activeDmxWays,
    required this.activePowerWays,
    required this.spareDmxWays,
    required this.sparePowerWays,
    required this.activeSneakWays,
    required this.spareSneakWays,
  });
}

// Creates an Excel Sheet that holds data extracted from the Outlets, that is to say if you viewed every show only through the eyes of whats coming out of the back of the racks,
// thus not including feeders, droppers etc.
void _runOutletAnalysis(
    Map<String, FixtureState> states, String projectFileDirectory) async {
  final dataByProjectName = states.map((projectName, state) =>
      MapEntry(projectName, _calculateLocationRequirments(state)));

  // Create Loom Counts Excel.
  final excel = Excel.createExcel();
  final sheet = excel.sheets[excel.getDefaultSheet()];

  if (sheet == null) {
    throw ('Null Sheet');
  }

  // Header Row.
  sheet.appendRow([
    TextCellValue('Project Name'),
    TextCellValue('Location Name'),
    TextCellValue('Active Power Ways'),
    TextCellValue('Active DMX Ways'),
    TextCellValue('Project Fixture Count'),
    TextCellValue('Project Motor Count'),
    TextCellValue('Project Cable Count'),
    TextCellValue('Project Total Cable Length'),
    TextCellValue('Project Fixture Type Count'),
    TextCellValue('Project Complexity Score'),
  ]);

  for (final projectEntry in dataByProjectName.entries) {
    final projectName = projectEntry.key;

    final fixtureCount = states[projectName]?.fixtures.length ?? 0;
    final motorCount = states[projectName]?.hoists.length ?? 0;
    final cableCount = states[projectName]?.cables.length ?? 0;
    final totalCableLength = (states[projectName]?.cables.values ?? [])
        .fold(0.0, (accum, value) => accum + value.length)
        .floor();

    final fixtureTypeCount = states[projectName]
            ?.fixtures
            .values
            .fold(<String, int>{}, (accum, value) {
              return Map<String, int>.from(accum
                ..update(value.typeId, (existing) => existing + 1,
                    ifAbsent: () => 1));
            })
            .keys
            .length ??
        0;

    final complexityScore = (fixtureCount * (fixtureTypeCount.clamp(1, 1000))) +
        (motorCount) +
        (cableCount) +
        (totalCableLength);

    for (final dataItem in projectEntry.value) {
      sheet.appendRow([
        TextCellValue(projectName),
        TextCellValue(dataItem.locationName),
        IntCellValue(dataItem.activePowerLoomCount),
        IntCellValue(dataItem.activeUniverses),
        IntCellValue(fixtureCount),
        IntCellValue(motorCount),
        IntCellValue(cableCount),
        IntCellValue(totalCableLength),
        IntCellValue(fixtureTypeCount),
        IntCellValue(complexityScore)
      ]);
    }
  }

  final bytes = excel.encode();

  if (bytes == null) {
    throw 'Unable to encode excel file';
  }

  final targetOutputFile =
      File(p.join(projectFileDirectory, 'output', 'Outlet_Analysis.xlsx'));

  await targetOutputFile.create(recursive: true);

  await targetOutputFile.writeAsBytes(bytes);

  launchUrl(Uri.file((targetOutputFile.path)));

  print('Done. Launching');
}

void _runHistorialAnalysis(
    Map<String, FixtureState> states, String projectFileDirectory) async {
  final dataByProjectName = states.map((projectName, state) =>
      MapEntry(projectName, _analyzeLoomUtilization(state)));

  // Create Loom Counts Excel.
  final excel = Excel.createExcel();
  final sheet = excel.sheets[excel.getDefaultSheet()];

  if (sheet == null) {
    throw ('Null Sheet');
  }

  // Header Row.
  sheet.appendRow([
    TextCellValue('Project Name'),
    TextCellValue('Is Permanent'),
    TextCellValue('Detected Class'),
    TextCellValue('Active Power Ways'),
    TextCellValue('Spare Power Ways'),
    TextCellValue('Active Sneak Ways'),
    TextCellValue('Spare Sneak Ways'),
    TextCellValue('Active DMX Ways'),
    TextCellValue('Spare DMX Ways'),
    TextCellValue('Combined Values Slug'),
    TextCellValue('Project Fixture Count'),
    TextCellValue('Project Motor Count'),
    TextCellValue('Project Cable Count'),
    TextCellValue('Project Total Cable Length'),
    TextCellValue('Project Fixture Type Count'),
    TextCellValue('Project Complexity Score'),
  ]);

  for (final projectEntry in dataByProjectName.entries) {
    final projectName = projectEntry.key;

    final fixtureCount = states[projectName]?.fixtures.length ?? 0;
    final motorCount = states[projectName]?.hoists.length ?? 0;
    final cableCount = states[projectName]?.cables.length ?? 0;
    final totalCableLength = (states[projectName]?.cables.values ?? [])
        .fold(0.0, (accum, value) => accum + value.length)
        .floor();

    final fixtureTypeCount = states[projectName]
            ?.fixtures
            .values
            .fold(<String, int>{}, (accum, value) {
              return Map<String, int>.from(accum
                ..update(value.typeId, (existing) => existing + 1,
                    ifAbsent: () => 1));
            })
            .keys
            .length ??
        0;

    final complexityScore = (fixtureCount * (fixtureTypeCount.clamp(1, 1000))) +
        (motorCount) +
        (cableCount) +
        (totalCableLength);

    for (final dataItem in projectEntry.value) {
      sheet.appendRow([
        TextCellValue(projectName),
        BoolCellValue(dataItem.isPermanent),
        TextCellValue(switch (dataItem.predominantCableClass) {
          CableClass.feeder => 'Feeder',
          CableClass.extension => 'Extension',
          CableClass.dropper => 'Dropper',
          CableClass.none => 'None',
        }),
        IntCellValue(dataItem.activePowerWays),
        IntCellValue(dataItem.sparePowerWays),
        IntCellValue(dataItem.activeSneakWays),
        IntCellValue(dataItem.spareSneakWays),
        IntCellValue(dataItem.activeDmxWays),
        IntCellValue(dataItem.spareDmxWays),
        TextCellValue(dataItem.combinedWaysSlug),
        IntCellValue(fixtureCount),
        IntCellValue(motorCount),
        IntCellValue(cableCount),
        IntCellValue(totalCableLength),
        IntCellValue(fixtureTypeCount),
        IntCellValue(complexityScore)
      ]);
    }
  }

  final bytes = excel.encode();

  if (bytes == null) {
    throw 'Unable to encode excel file';
  }

  final targetOutputFile =
      File(p.join(projectFileDirectory, 'output', 'Direct_Loom_Analysis.xlsx'));

  await targetOutputFile.create(recursive: true);

  await targetOutputFile.writeAsBytes(bytes);

  launchUrl(Uri.file((targetOutputFile.path)));

  print('Done. Launching');
}

void _runInitialPowerMultiOutletAnalysis(
    Map<String, FixtureState> states, String projectFileDirectory) async {
  final loomCountsByProjectName = states.map(
      (projectName, state) => MapEntry(projectName, _analyzeLoomCount(state)));

  // Create Loom Counts Excel.
  final excel = Excel.createExcel();
  final sheet = excel.sheets[excel.getDefaultSheet()];

  if (sheet == null) {
    throw ('Null Sheet');
  }

  // Header Row.
  sheet.appendRow([
    TextCellValue('Project Name'),
    TextCellValue('Location Name'),
    TextCellValue('Active Power Loom Count'),
    TextCellValue('Spare Power Loom Count'),
    TextCellValue('Combined Power Loom Count'),
    TextCellValue('Project Fixture Count'),
    TextCellValue('Project Motor Count'),
    TextCellValue('Project Cable Count'),
    TextCellValue('Project Total Cable Length'),
    TextCellValue('Project Fixture Type Count'),
    TextCellValue('Project Complexity Score'),
  ]);

  for (final entry in loomCountsByProjectName.entries) {
    final projectName = entry.key;
    final loomCounts = entry.value;
    final fixtureCount = states[projectName]?.fixtures.length ?? 0;
    final motorCount = states[projectName]?.hoists.length ?? 0;
    final cableCount = states[projectName]?.cables.length ?? 0;
    final totalCableLength = (states[projectName]?.cables.values ?? [])
        .fold(0.0, (accum, value) => accum + value.length)
        .floor();

    final fixtureTypeCount = states[projectName]
            ?.fixtures
            .values
            .fold(<String, int>{}, (accum, value) {
              return Map<String, int>.from(accum
                ..update(value.typeId, (existing) => existing + 1,
                    ifAbsent: () => 1));
            })
            .keys
            .length ??
        0;

    final complexityScore = (fixtureCount * (fixtureTypeCount.clamp(1, 1000))) +
        (motorCount) +
        (cableCount) +
        (totalCableLength);

    for (final count in loomCounts) {
      sheet.appendRow([
        TextCellValue(projectName),
        TextCellValue(count.locationName),
        IntCellValue(count.activePowerLoomCount),
        IntCellValue(count.sparePowerLoomCount),
        IntCellValue(count.activePowerLoomCount + count.sparePowerLoomCount),
        IntCellValue(fixtureCount),
        IntCellValue(motorCount),
        IntCellValue(cableCount),
        IntCellValue(totalCableLength),
        IntCellValue(fixtureTypeCount),
        IntCellValue(complexityScore)
      ]);
    }
  }

  final bytes = excel.encode();

  if (bytes == null) {
    throw 'Unable to encode excel file';
  }

  final targetOutputFile = File(
      p.join(projectFileDirectory, 'output', 'Loom_Counts_By_Location.xlsx'));

  await targetOutputFile.create(recursive: true);

  await targetOutputFile.writeAsBytes(bytes);

  launchUrl(Uri.file((targetOutputFile.path)));

  print('Done. Launching');
}

List<_LocationLoomCount> _analyzeLoomCount(FixtureState state) {
  return state.powerMultiOutlets.values
      .groupListsBy((multi) => multi.locationId)
      .entries
      .map((entry) {
    final locationId = entry.key;
    final multiOutletsInLocation = entry.value;

    return _LocationLoomCount(
        locationName: state.locations[locationId]?.name ?? 'Unknown',
        activePowerLoomCount: multiOutletsInLocation.length,
        sparePowerLoomCount:
            _calculateSparePowerLoomsInLocation(state, locationId));
  }).toList();
}

int _calculateSparePowerLoomsInLocation(FixtureState state, String locationId) {
  final cablesByLoomId =
      state.cables.values.groupListsBy((cable) => cable.loomId);

  final spareCablesByLocationId = cablesByLoomId.map((loomId, cables) {
    return MapEntry(
      _guessLocationId(state, cables),
      cables
          .where((cable) =>
              cable.isSpare &&
              cable.upstreamId.isEmpty &&
              (cable.type == CableType.socapex ||
                  cable.type == CableType.wieland6way))
          .toList(),
    );
  });

  return spareCablesByLocationId[locationId]?.length ?? 0;
}

String _guessLocationId(FixtureState state, List<CableModel> cables) {
  final locationIds = cables.map(
      (cable) => state.powerMultiOutlets[cable.outletId]?.locationId ?? '');

  return locationIds.firstWhereOrNull((id) => id.isNotEmpty) ?? '';
}

class _LocationLoomCount {
  final String locationName;
  final int activePowerLoomCount;
  final int sparePowerLoomCount;

  _LocationLoomCount({
    required this.locationName,
    required this.activePowerLoomCount,
    required this.sparePowerLoomCount,
  });
}

class _LocationRequirments {
  final String locationName;
  final int activePowerLoomCount;
  final int activeUniverses;

  _LocationRequirments({
    required this.locationName,
    required this.activePowerLoomCount,
    required this.activeUniverses,
  });
}
