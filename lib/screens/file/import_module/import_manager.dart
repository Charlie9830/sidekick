import 'dart:io';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/enums.dart';
import 'package:sidekick/excel/read_fixture_type_database.dart';
import 'package:sidekick/excel/read_fixtures_patch_data.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_type_mapping_parser.dart';

import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/screens/file/import_module/fixture_mapping_step.dart';
import 'package:sidekick/screens/file/import_module/fixture_mapping_view_model.dart';
import 'package:sidekick/screens/file/import_module/map_fixture_types.dart';

import 'package:sidekick/screens/file/import_module/mvr_import_settings.dart';
import 'package:sidekick/screens/file/import_module/patch_import_settings.dart';
import 'package:sidekick/screens/file/import_module/read_raw_fixtures.dart';
import 'package:sidekick/screens/file/import_module/select_file_control.dart';
import 'package:sidekick/snack_bars/generic_error_snack_bar.dart';
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
  bool _showDataLaundryErrorPanel = true;
  bool _isFixtureMappingPathValid = false;
  bool _isFixtureDatabasePathValid = false;

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
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text('Import Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.error),
            onPressed: () => setState(
                () => _showDataLaundryErrorPanel = !_showDataLaundryErrorPanel),
          ),
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
              width: 180,
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
                  stepRadius: 32,
                  steps: const [
                    EasyStep(icon: Icon(Icons.file_open), title: 'Select File'),
                    EasyStep(
                        icon: Icon(Icons.cleaning_services),
                        title: 'Fixture Type Mapping'),
                    EasyStep(icon: Icon(Icons.table_view), title: 'View'),
                    EasyStep(
                      icon: Icon(Icons.merge),
                      title: 'Merge',
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
                  _ => Text('No Content'),
                },
              ),
            ],
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _handleNextButtonPressed,
          label: const Text('Next'),
          icon: const Icon(Icons.arrow_circle_right)),
    );
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
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  void _handleNextButtonPressed() async {
    final nextStep =
        ImportManagerStep.byStepNumber[widget.vm.step.stepNumber + 1];

    if (nextStep == null) {
      throw UnimplementedError("No more steps to go to");
    }

    widget.vm.onNextStep?.call(nextStep);

    switch (nextStep) {
      case ImportManagerStep.fileSelect:
        break;
      case ImportManagerStep.fixtureMapping:
        _loadFixtureMappingStep();
      case ImportManagerStep.viewData:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  List<FixtureMappingViewModel> _selectFixtureMappingViewModels(
      Map<String, FixtureMappingModel> fixtureMappings) {
    final databaseEntriesByShortName =
        _fixtureTypes.map((key, value) => MapEntry(value.shortName, value));

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
