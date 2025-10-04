import 'dart:io';
import 'package:collection/collection.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/excel/read_fixture_type_database.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_type_mapping_parser.dart';
import 'package:sidekick/redux/models/fixture_model.dart';

import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/screens/file/import_module/fixture_mapping_step.dart';
import 'package:sidekick/screens/file/import_module/fixture_mapping_view_model.dart';
import 'package:sidekick/screens/file/import_module/import_manager_result.dart';
import 'package:sidekick/screens/file/import_module/incoming_fixture_item_view_model.dart';
import 'package:sidekick/screens/file/import_module/map_fixture_types.dart';
import 'package:sidekick/screens/file/import_module/merge_data_step.dart';

import 'package:sidekick/screens/file/import_module/mvr_import_settings.dart';
import 'package:sidekick/screens/file/import_module/patch_import_settings.dart';
import 'package:sidekick/screens/file/import_module/raw_fixture_model.dart';
import 'package:sidekick/screens/file/import_module/raw_location_model.dart';
import 'package:sidekick/screens/file/import_module/read_raw_fixtures.dart';
import 'package:sidekick/screens/file/import_module/select_file_control.dart';
import 'package:sidekick/screens/file/import_module/view_data_step.dart';
import 'package:sidekick/snack_bars/generic_error_snack_bar.dart';
import 'package:sidekick/view_models/fixture_table_view_model.dart';
import 'package:sidekick/view_models/import_manager_view_model.dart';

class ImportManager extends StatefulWidget {
  final ImportManagerViewModel vm;
  const ImportManager({
    super.key,
    required this.vm,
  });

  @override
  State<ImportManager> createState() => _ImportManagerState();
}

class _ImportManagerState extends State<ImportManager> {
  late final FocusNode _selectionFocusNode;
  Map<String, FixtureTypeModel> _fixtureTypes = {};
  Map<String, FixtureMappingModel> _fixtureTypeMapping = {};
  late PatchImportSettings _importSettings;
  String _fixturePatchFilePath = '';
  bool _isFixtureMappingPathValid = false;
  bool _isFixtureDatabasePathValid = false;
  List<RawFixtureModel> _incomingFixtures = const [];
  List<RawLocationModel> _incomingLocations = const [];
  Map<String, String> _locationMapping = {};

  @override
  void initState() {
    _selectionFocusNode = FocusNode();
    _importSettings = PatchImportSettings(
        source: PatchSource.mvr,
        mvrLocationDataSource: MvrLocationDataSource.layers);

    _doAsyncSetup();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final canProgress = _canProgress();
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text('Import Manager'),
        actions: [
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefreshButtonPressed,
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
              width: 120,
              child: Card(
                elevation: 2,
                child: EasyStepper(
                  lineStyle: const LineStyle(
                    lineType: LineType.normal,
                  ),
                  direction: Axis.vertical,
                  activeStep: widget.vm.step.stepNumber,
                  enableStepTapping: false,
                  showLoadingAnimation: false,
                  defaultStepBorderType: BorderType.normal,
                  stepRadius: 24,
                  activeStepBackgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  finishedStepBackgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  showStepBorder: true,
                  borderThickness: 2,
                  unreachedStepBorderColor: Colors.grey.shade800,
                  steps: const [
                    EasyStep(icon: Icon(Icons.file_open)),
                    EasyStep(
                      icon: Icon(Icons.cleaning_services),
                    ),
                    EasyStep(
                      icon: Icon(Icons.table_view),
                    ),
                    EasyStep(
                      icon: Icon(Icons.merge),
                    ),
                  ],
                ),
              )),
          Expanded(
              child: Column(
            children: [
              Expanded(
                child: switch (widget.vm.step) {
                  ImportManagerStep.fileSelect => SelectFileControl(
                      fixtureDatabaseFilePath:
                          widget.vm.fixtureDatabaseFilePath,
                      fixtureMappingFilePath: widget.vm.fixtureMappingFilePath,
                      onFixtureDatabaseFilePathChanged: _loadFixtureDatabase,
                      onFixtureMappingFilePathChanged: _loadFixtureMapping,
                      isFixtureDatabaseValid: _isFixtureDatabasePathValid,
                      isFixtureMappingValid: _isFixtureMappingPathValid,
                      settings: _importSettings,
                      onSettingsUpdated: (newSettings) =>
                          setState(() => _importSettings = newSettings),
                      onPatchFilePathChanged: (newValue) =>
                          setState(() => _fixturePatchFilePath = newValue),
                      fixturePatchFilePath: _fixturePatchFilePath,
                    ),
                  ImportManagerStep.fixtureMapping => FixtureMappingStep(
                      viewModels:
                          _selectFixtureMappingViewModels(_fixtureTypeMapping),
                      fixtureDatabaseFilePath:
                          widget.vm.fixtureDatabaseFilePath,
                      fixtureMappingFilePath: widget.vm.fixtureMappingFilePath,
                    ),
                  ImportManagerStep.viewData => ViewDataStep(
                      showDiffOverlays: widget.vm.existingFixtures.isNotEmpty,
                      vms: _selectIncomingFixtureViewModels(
                        _incomingFixtures,
                        _fixtureTypeMapping,
                      ),
                    ),
                  ImportManagerStep.mergeData => MergeDataStep(
                      locationMapping: _locationMapping,
                      existingLocations: widget.vm.existingLocations,
                      incomingLocations:
                          Map<String, RawLocationModel>.fromEntries(
                              _incomingLocations.map(
                                  (loc) => MapEntry(loc.generatedId, loc))),
                      onLocationMappingUpdated: (mapping) =>
                          setState(() => _locationMapping = mapping),
                    )
                },
              ),
            ],
          )),
        ],
      ),
      floatingActionButton: Column(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.vm.step != ImportManagerStep.fileSelect)
            FloatingActionButton.small(
              backgroundColor: Colors.indigo,
              onPressed: _handleBackButtonPressed,
              child: const Icon(Icons.arrow_back),
            ),
          FloatingActionButton.extended(
              onPressed: canProgress ? _handleNextButtonPressed : null,
              tooltip: canProgress == false ? _getProgressHaltedText() : null,
              label: const Text('Next'),
              icon: const Icon(Icons.arrow_circle_right)),
        ],
      ),
    );
  }

  String _getProgressHaltedText() {
    final currentStep = widget.vm.step;
    return switch (currentStep) {
      ImportManagerStep.fileSelect => 'You must select a patch file to import.',
      ImportManagerStep.fixtureMapping => _isFixtureDatabasePathValid == false
          ? 'You must select a valid Fixture Database file'
          : _isFixtureMappingPathValid == false
              ? 'You must select a valid Fixture mapping file'
              : 'You must correct all errors before proceeding',
      _ => '',
    };
  }

  bool _canProgress() {
    final currentStep = widget.vm.step;

    return switch (currentStep) {
      ImportManagerStep.fileSelect => _isFixtureDatabasePathValid &&
          _isFixtureMappingPathValid &&
          _fixturePatchFilePath.isNotEmpty,
      ImportManagerStep.fixtureMapping =>
        _selectFixtureMappingViewModels(_fixtureTypeMapping)
            .map((mapping) => mapping.existsInDatabase)
            .every((item) => item == true),
      ImportManagerStep.viewData => true,
      ImportManagerStep.mergeData => true
    };
  }

  void _handleBackButtonPressed() {
    final prevStep =
        ImportManagerStep.byStepNumber[widget.vm.step.stepNumber - 1];

    if (prevStep == null) {
      return;
    }

    widget.vm.goToStep?.call(prevStep);
  }

  List<IncomingFixtureItemViewModel> _selectIncomingFixtureViewModels(
      List<RawFixtureModel> incomingFixtures,
      Map<String, FixtureMappingModel> fixtureTypeMapping) {
    final allFixtureIds = {
      ...incomingFixtures.map((fixture) =>
          fixture.mvrId.isNotEmpty ? fixture.mvrId : fixture.generatedId),
      ...widget.vm.existingFixtures.keys,
    };

    final incomingFixturesByUid = Map<String, RawFixtureModel>.fromEntries(
        incomingFixtures.map((fixture) => MapEntry(
            fixture.mvrId.isNotEmpty ? fixture.mvrId : fixture.generatedId,
            fixture)));

    final incomingLocationLookup = Map<String, RawLocationModel>.fromEntries(
        _incomingLocations.map((incomingLocation) => MapEntry(
            incomingLocation.mvrId.isNotEmpty
                ? incomingLocation.mvrId
                : incomingLocation.generatedId,
            incomingLocation)));

    return allFixtureIds.map((uid) {
      final incomingFixture = incomingFixturesByUid[uid];

      FixtureMappingModel? mapping;
      if (incomingFixture != null) {
        mapping = _fixtureTypeMapping[FixtureMappingModel.getSourceKey(
            incomingFixture.fixtureType, incomingFixture.fixtureMode)];
      }

      final incomingFixtureVm = incomingFixture == null
          ? null
          : FixtureViewModel(
              fid: incomingFixture.fixtureId,
              address: incomingFixture.address.toSlashNotationString(),
              type: mapping?.mappedFixtureType ?? '',
              mode: mapping?.mappedFixtureMode ?? '',
              location: incomingLocationLookup[
                          incomingFixture.mvrLocationId.isNotEmpty
                              ? incomingFixture.mvrLocationId
                              : incomingFixture.generatedLocationId]
                      ?.name ??
                  '',
            );

      return IncomingFixtureItemViewModel(
        existingFixture: widget.vm.existingFixtureViewModels[uid],
        incomingFixture: incomingFixtureVm,
      );
    }).toList();
  }

  void _doAsyncSetup() async {
    // Load Fixture Mapping File.
    if (widget.vm.fixtureMappingFilePath.isNotEmpty) {
      _loadFixtureMapping(widget.vm.fixtureMappingFilePath);
    }

    // Load Fixture Database.
    if (widget.vm.fixtureDatabaseFilePath.isNotEmpty) {
      _loadFixtureDatabase(widget.vm.fixtureDatabaseFilePath);
    }
  }

  Future<Map<String, FixtureTypeModel>?> _loadFixtureDatabase(
      String path) async {
    widget.vm.onFixtureDatabaseFilePathChanged(path);

    if (path.isEmpty) {
      setState(() {
        _isFixtureDatabasePathValid = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message: 'Invalid Path to Fixture Database. Provided path is empty'));

      return null;
    }

    if (await File(path).exists() == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message:
              "Fixture Database file was not found at the path provided."));

      setState(() {
        _isFixtureDatabasePathValid = false;
      });

      return null;
    }

    final fixtureDatabaseReadResult = await readFixtureTypeDatabase(path);

    if (fixtureDatabaseReadResult.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message:
              "An error occurred reading the Fixture Database. ${fixtureDatabaseReadResult.errorMessage}"));

      setState(() => _isFixtureDatabasePathValid = false);

      return null;
    }

    setState(() {
      _isFixtureDatabasePathValid = true;
      _fixtureTypes = fixtureDatabaseReadResult.fixtureTypes;
    });

    return fixtureDatabaseReadResult.fixtureTypes;
  }

  Future<List<FixtureMatchModel>?> _loadFixtureMapping(String path) async {
    widget.vm.onFixtureMappingPathChanged(path);

    if (path.isEmpty) {
      setState(() {
        _isFixtureMappingPathValid = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message:
              'Invalid Path to Fixture Mapping file. Provided path is empty'));

      return null;
    }

    final file = File(path);

    if (await file.exists() == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message: "Fixture mapping file was not found at the path provided."));

      setState(() {
        _isFixtureMappingPathValid = false;
      });

      return null;
    }

    final parser = FixtureTypeMappingParser();

    final List<FixtureMatchModel> fixtureMatchers;
    try {
      fixtureMatchers = await parser.parseMappingFile(file);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          genericErrorSnackBar(
            context: context,
            message: "An error occurred reading the Fixture Mapping File:",
            extendedMessage: error.toString(),
          ),
        );
      }
      setState(() => _isFixtureMappingPathValid = false);
      return null;
    }

    if (fixtureMatchers.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message:
              "Invalid File format, ensure the provided file meets the correct Fixture Mapping file schema. No Fixture match rules were found."));
      setState(() => _isFixtureMappingPathValid = false);
      return null;
    }

    setState(() {
      _isFixtureMappingPathValid = true;
    });

    return fixtureMatchers;
  }

  void _handleRefreshButtonPressed() async {
    switch (widget.vm.step) {
      case ImportManagerStep.fileSelect:
        return;
      case ImportManagerStep.fixtureMapping:
        _loadFixtureMappingStep();
      case ImportManagerStep.viewData:
        return;
      case ImportManagerStep.mergeData:
        return;
    }
  }

  void _loadViewDataStep() async {}

  void _loadMergeDataStep() async {
    // Attempt to Map existing Locations to incoming locations as a starting point.
    final existingLocationsByName = widget.vm.existingLocations.values
        .groupListsBy((location) => location.name)
        .map((name, locations) => MapEntry(name, locations.first));

    final incomingLocationsByName = Map<String, RawLocationModel>.fromEntries(
        _incomingLocations
            .map((incoming) => MapEntry(incoming.name, incoming)));

    final locationMappings = Map<String, String>.fromEntries(
        existingLocationsByName
            .entries
            .map((existingLocationEntry) =>
                incomingLocationsByName.keys.contains(existingLocationEntry.key)
                    ? MapEntry(
                        incomingLocationsByName[existingLocationEntry.key]!
                            .generatedId,
                        existingLocationEntry.value.uid)
                    : null)
            .nonNulls);

    setState(() {
      _locationMapping = locationMappings;
    });
  }

  void _handleNextButtonPressed() async {
    ImportManagerStep? nextStep =
        ImportManagerStep.byStepNumber[widget.vm.step.stepNumber + 1];

    // Guard against needlessly entering into the Grandma2 Patch Location Merging workflow.
    if (nextStep == ImportManagerStep.mergeData) {
      if (_importSettings.source == PatchSource.mvr) {
        // No need to enter merge step if we are coming from MVR.
        nextStep = null;
      }

      if (widget.vm.existingLocations.isEmpty) {
        // No need to enter merge step if we don't have any existing locations to merge with.
        nextStep = null;
      }
    }

    if (nextStep == null) {
      _handleFinish();
      return;
    }

    widget.vm.goToStep?.call(nextStep);

    switch (nextStep) {
      case ImportManagerStep.fileSelect:
        break;
      case ImportManagerStep.fixtureMapping:
        _loadFixtureMappingStep();
      case ImportManagerStep.viewData:
        _loadViewDataStep();
      case ImportManagerStep.mergeData:
        _loadMergeDataStep();
    }
  }

  void _handleFinish() {
    final fixtureTypesByShortName =
        _getFixtureDatabaseEntriesByShortName(_fixtureTypes);

    List<FixtureModel> fixtures =
        _incomingFixtures.mapIndexed((index, incomingFixture) {
      final incomingId = incomingFixture.mvrId.isNotEmpty
          ? incomingFixture.mvrId
          : incomingFixture.generatedId;
      final existing = widget.vm.existingFixtureViewModels[incomingId];

      final fixtureMapping = _fixtureTypeMapping[
          FixtureMappingModel.getSourceKey(
              incomingFixture.fixtureType, incomingFixture.fixtureMode)];

      final fixtureTypeId =
          fixtureTypesByShortName[fixtureMapping!.mappedFixtureType]!.uid;
      final fixtureMode = fixtureMapping.mappedFixtureMode;

      return FixtureModel(
        uid: incomingId,
        dmxAddress: incomingFixture.address,
        fid: incomingFixture.fixtureId,
        typeId: fixtureTypeId,
        mode: fixtureMode,
        locationId: incomingFixture.mvrLocationId.isNotEmpty
            ? incomingFixture.mvrLocationId
            : incomingFixture.generatedLocationId,
        sequence: existing?.sequence ?? index + 1,
      );
    }).toList();

    final locationIdRemappings = <_LocationIdRemapping>[];

    final locations = [
      // Process incoming Locations and Merge with Existing Locations if applicable.
      ..._incomingLocations.map((incomingLocation) {
        final existingMvrLocation =
            widget.vm.existingLocations[incomingLocation.mvrId];

        if (existingMvrLocation != null) {
          // Matching MVR Location found, Merge properties from the incoming location in, nominally only name.
          return existingMvrLocation.copyWith(
            name: incomingLocation.name,
          );
        }

        final existingMappedLocation = widget.vm
            .existingLocations[_locationMapping[incomingLocation.generatedId]];

        if (existingMappedLocation != null) {
          // Keep track of remapping to existing locations as we need to update the reference the fixture has later.
          // TODO: This is bad practice, Side affect from a pure function.
          locationIdRemappings.add(_LocationIdRemapping(
              generatedIncomingLocationId: incomingLocation.generatedId,
              mappedId: existingMappedLocation.uid));

          // Found a matching location (That was manually Mapped by the user)
          return existingMappedLocation.copyWith(
            name: incomingLocation.name,
          );
        }

        // Nothing existing. Create a new one.
        return LocationModel(
            uid: incomingLocation.mvrId.isNotEmpty
                ? incomingLocation.mvrId
                : incomingLocation.generatedId,
            name: incomingLocation.name,
            color: LocationModel.matchColor(incomingLocation.name),
            multiPrefix: LocationModel.matchMultiPrefix(incomingLocation.name),
            delimiter:
                LocationModel.getDefaultDelimiterValue(incomingLocation.name));
      }),

      // Marry with Existing Hybrid Locations.
      // TODO: This will likely need to be smarter about how it marries in hybrid locations. For example, there should be some sort of handling
      // for when incoming locations does not contain a location that one of these Hybrids points to.
      ...widget.vm.existingLocations.values
          .where((location) => location.isHybrid),

      // Marry with existing Rigging Only Locations.
      ...widget.vm.existingLocations.values
          .where((location) => location.isRiggingOnlyLocation),
    ];

    // Adjust each incoming fixtures locationId to match any remappings we made.
    // TODO: This is probably Big O notation terrible.
    if (locationIdRemappings.isNotEmpty) {
      for (final remapping in locationIdRemappings) {
        fixtures = fixtures
            .map((fixture) =>
                fixture.locationId == remapping.generatedIncomingLocationId
                    ? fixture.copyWith(locationId: remapping.mappedId)
                    : fixture)
            .toList();
      }
    }

    final existingInUseFixtureTypes = widget.vm.existingFixtures.values
        .map((fixture) => fixture.typeId)
        .toSet()
        .map((typeId) => widget.vm.existingFixtureTypes[typeId])
        .nonNulls
        .toModelMap();

    final mergedFixtureTypes = _fixtureTypes.values.map((incomingType) {
      final existingType = existingInUseFixtureTypes[incomingType.uid];

      return incomingType.copyWith(
        maxPiggybacks: existingType?.maxPiggybacks,
        shortName: existingType?.shortName,
      );
    }).toList();

    Navigator.of(context).pop(ImportManagerResult(
        fixtures: fixtures.toList(),
        locations: locations.toList(),
        fixtureTypes: mergedFixtureTypes));
  }

  Map<String, FixtureTypeModel> _getFixtureDatabaseEntriesByShortName(
      Map<String, FixtureTypeModel> fixtureTypes) {
    return fixtureTypes.map((key, value) => MapEntry(value.shortName, value));
  }

  List<FixtureMappingViewModel> _selectFixtureMappingViewModels(
      Map<String, FixtureMappingModel> fixtureMappings) {
    final databaseEntriesByShortName =
        _getFixtureDatabaseEntriesByShortName(_fixtureTypes);

    return fixtureMappings.entries.map((entry) {
      final mapping = entry.value;

      return FixtureMappingViewModel(
          mapping: mapping,
          existsInDatabase: databaseEntriesByShortName
              .containsKey(mapping.mappedFixtureType));
    }).toList();
  }

  void _loadFixtureMappingStep() async {
    final fixtureReadResult = await readRawFixtures(
        settings: _importSettings, patchFilePath: _fixturePatchFilePath);

    if (fixtureReadResult.error != null && mounted) {
      // Something went wrong reading the patch data. Bail.
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context, message: fixtureReadResult.error!));
      return;
    }

    final fixtureMatchers =
        await _loadFixtureMapping(widget.vm.fixtureMappingFilePath);

    if (fixtureMatchers == null) {
      // Something has gone wrong reading the Fixture mapping File. We can bail without informing the user as _loadFixtureMapping will
      // have already done it.
      return;
    }

    final fixtureTypeMapping = mapFixtureTypes(
        rawFixtures: fixtureReadResult.fixtures,
        fixtureMatchers: fixtureMatchers,
        flavour: _kPatchSourceToMappingFlavour[_importSettings.source]!);

    final fixtureDatabaseResult =
        await _loadFixtureDatabase(widget.vm.fixtureDatabaseFilePath);

    if (fixtureDatabaseResult == null) {
      // Something has gone wrong reading the Fixture Database File. We can bail without informing the user as _loadFixtureDatabase will
      // have already done it.
      return;
    }

    setState(() {
      _fixtureTypeMapping = fixtureTypeMapping;
      _fixtureTypes = fixtureDatabaseResult;
      _incomingFixtures = fixtureReadResult.fixtures;
      _incomingLocations = fixtureReadResult.locations;
    });
  }

  @override
  void dispose() {
    _selectionFocusNode.dispose();
    super.dispose();
  }
}

const _kPatchSourceToMappingFlavour = {
  PatchSource.grandMA2XML: MappingFlavour.ma2,
  PatchSource.mvr: MappingFlavour.mvr,
};

class _LocationIdRemapping {
  final String generatedIncomingLocationId;
  final String mappedId;

  _LocationIdRemapping({
    required this.generatedIncomingLocationId,
    required this.mappedId,
  });
}
