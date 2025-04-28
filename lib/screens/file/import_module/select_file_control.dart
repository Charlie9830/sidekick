import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/excel/read_fixture_type_database.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/fixture_type_mapping_parser/fixture_type_mapping_parser.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/screens/file/import_module/file_valid_icon.dart';
import 'package:sidekick/screens/file/import_module/mvr_import_settings.dart';
import 'package:sidekick/snack_bars/generic_error_snack_bar.dart';
import 'package:path/path.dart' as p;

enum PatchSource {
  excel,
  grandMA2XML,
  mvr,
}

class SelectFileControl extends StatefulWidget {
  final String fixtureTypeMappingFilePath;
  final String fixtureDatabaseSpreadsheetFilePath;
  final void Function(Map<String, FixtureTypeModel> fixtureTypes)
      onFixtureTypesLoaded;

  final void Function(String path) onFixtureMappingFilePathChanged;
  final void Function(String path) onFixtureDatabaseFilePathChanged;

  const SelectFileControl({
    super.key,
    this.fixtureTypeMappingFilePath = '',
    this.fixtureDatabaseSpreadsheetFilePath = '',
    required this.onFixtureTypesLoaded,
    required this.onFixtureDatabaseFilePathChanged,
    required this.onFixtureMappingFilePathChanged,
  });

  @override
  State<SelectFileControl> createState() => _SelectFileControlState();
}

class _SelectFileControlState extends State<SelectFileControl> {
  PatchSource _selectedSource = PatchSource.mvr;
  String _targetFilePath = '';
  String _fixtureTypeMappingFilePath = '';
  String _fixtureDatabaseSpreadsheetFilePath = '';
  bool _isFixtureTypeMappingFilePathValid = false;
  bool _isFixtureDatabaseSpreadsheetFilePathValid = false;
  late MvrImportSettings _mvrImportSettings;

  @override
  void initState() {
    super.initState();
    _fixtureTypeMappingFilePath = widget.fixtureTypeMappingFilePath;
    _fixtureDatabaseSpreadsheetFilePath =
        widget.fixtureDatabaseSpreadsheetFilePath;
    _doAsyncSetup();

    _mvrImportSettings =
        MvrImportSettings(locationDataSource: MvrLocationDataSource.layers);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSourceSelector(context),
        // Content
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  switch (_selectedSource) {
                    PatchSource.excel => "Excel",
                    PatchSource.grandMA2XML => "GrandMA2 Fixture Layers",
                    PatchSource.mvr => "MVR File",
                  },
                  style: Theme.of(context).textTheme.titleSmall),
              const Divider(),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _handlePatchFileSelect,
                    child: Text(_targetFilePath.isEmpty ? 'Select' : 'Change'),
                  ),
                  const SizedBox(width: 16),
                  Text(_targetFilePath,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                  child: switch (_selectedSource) {
                PatchSource.excel =>
                  const Text("Excel specific settings not implemented yet"),
                PatchSource.grandMA2XML => const SizedBox(),
                PatchSource.mvr => _buildMvrImportSettings(),
              }),
              const Divider(),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixture Mapping XML File.
                  Text('Fixture Type Mapping File',
                      style: Theme.of(context).textTheme.labelMedium),
                  Row(
                    spacing: 12,
                    children: [
                      FileValidIcon(
                        isValid: _isFixtureTypeMappingFilePathValid,
                      ),
                      TextButton(
                        onPressed: _handleFixtureTypeMappingSelect,
                        child: Text(
                          _fixtureTypeMappingFilePath.isEmpty
                              ? "Select"
                              : "Change",
                        ),
                      ),
                      Text(_fixtureTypeMappingFilePath,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Fixture Database Spreadsheet.
                  Text('Fixture Database',
                      style: Theme.of(context).textTheme.labelMedium),
                  Row(
                    spacing: 12,
                    children: [
                      FileValidIcon(
                        isValid: _isFixtureDatabaseSpreadsheetFilePathValid,
                      ),
                      TextButton(
                        onPressed: _handleFixtureDatabaseSelect,
                        child: Text(
                          _fixtureDatabaseSpreadsheetFilePath.isEmpty
                              ? "Select"
                              : "Change",
                        ),
                      ),
                      Text(_fixtureDatabaseSpreadsheetFilePath,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              )
            ],
          ),
        ))
      ],
    );
  }

  Widget _buildMvrImportSettings() {
    return Column(
      children: [
        Row(
          spacing: 16,
          children: [
            Text('Fixture Location data source ie: Truss name',
                style: Theme.of(context).textTheme.labelMedium),
            DropdownMenu<MvrLocationDataSource>(
              enableFilter: false,
              enableSearch: false,
              initialSelection: _mvrImportSettings.locationDataSource,
              onSelected: (value) => setState(() => _mvrImportSettings =
                  _mvrImportSettings.copyWith(locationDataSource: value)),
              dropdownMenuEntries: const [
                DropdownMenuEntry(
                    value: MvrLocationDataSource.layers, label: 'Layers'),
                DropdownMenuEntry(
                    value: MvrLocationDataSource.classes, label: 'Classes'),
                DropdownMenuEntry(
                    value: MvrLocationDataSource.position,
                    label: 'Position Attribute'),
              ],
            )
          ],
        ),
      ],
    );
  }

  Future<(bool, List<FixtureMatchModel>, String? errorMessage)>
      _validateFixtureTypeMappingFilePath(String path) async {
    if (path.isEmpty) {
      return (
        false,
        <FixtureMatchModel>[],
        'Invalid Fixture Type Mapping path'
      );
    }

    final file = File(path);

    if (await file.exists() == false) {
      return (
        false,
        <FixtureMatchModel>[],
        'Fixture Type Mapping file does not exist'
      );
    }

    final parser = FixtureTypeMappingParser();

    final List<FixtureMatchModel> fixtureMatchers;

    try {
      fixtureMatchers = await parser.parseMappingFile(file);
    } catch (error) {
      return (
        false,
        <FixtureMatchModel>[],
        'An error occurred parsing the fixture mapping file: $error'
      );
    }

    if (fixtureMatchers.isEmpty) {
      return (
        false,
        fixtureMatchers,
        'Invalid File format, ensure the provided file meets the correct Fixture Mapping file schema. No Fixture match rules were found.'
      );
    }

    return (true, fixtureMatchers, null);
  }

  Future<(bool, FixtureTypeDatabaseReadResult?, String? errorMessage)>
      _validateFixtureDatabaseSpreadsheetFilePath(String path) async {
    if (path.isEmpty) {
      return (false, null, 'Invalid path');
    }

    if (await File(path).exists() == false) {
      return (false, null, 'Fixture Database file does not exist');
    }

    final fixtureDatabaseReadResult = await readFixtureTypeDatabase(path);

    if (fixtureDatabaseReadResult.errorMessage != null) {
      return (
        false,
        fixtureDatabaseReadResult,
        'An error occurred reading the fixture database file: ${fixtureDatabaseReadResult.errorMessage}'
      );
    }

    return (true, fixtureDatabaseReadResult, null);
  }

  void _doAsyncSetup() async {
    // Fixture Type Mapping Setup.
    if (widget.fixtureTypeMappingFilePath.isNotEmpty) {
      final (
        isFixtureTypeMappingValid,
        fixtureMappingResult,
        fixtureMappingError
      ) = await _validateFixtureTypeMappingFilePath(
          widget.fixtureTypeMappingFilePath);
      setState(() {
        _isFixtureTypeMappingFilePathValid = isFixtureTypeMappingValid;
        _fixtureTypeMappingFilePath = widget.fixtureTypeMappingFilePath;
      });

      if (isFixtureTypeMappingValid == false && fixtureMappingError != null) {
        ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
            context: context, message: fixtureMappingError));
      }
    }

    // Fixture Database setup.
    if (widget.fixtureDatabaseSpreadsheetFilePath.isNotEmpty) {
      final (isFixtureDatabaseValid, databaseResult, fixtureDatabaseError) =
          await _validateFixtureDatabaseSpreadsheetFilePath(
              widget.fixtureDatabaseSpreadsheetFilePath);

      setState(() {
        _isFixtureDatabaseSpreadsheetFilePathValid = isFixtureDatabaseValid;
        _fixtureDatabaseSpreadsheetFilePath =
            widget.fixtureDatabaseSpreadsheetFilePath;
      });

      if (isFixtureDatabaseValid == true && databaseResult != null) {
        widget.onFixtureTypesLoaded(databaseResult.fixtureTypes);
      }

      if (isFixtureDatabaseValid == false && fixtureDatabaseError != null) {
        ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
            context: context, message: fixtureDatabaseError));
      }
    }
  }

  void _handleFixtureTypeMappingSelect() async {
    final file = await openFile(
      confirmButtonText: "Select",
      acceptedTypeGroups: kXmlFileTypes,
      initialDirectory: _fixtureTypeMappingFilePath.isNotEmpty
          ? p.dirname(_fixtureTypeMappingFilePath)
          : null,
    );

    if (file == null) {
      return;
    }

    final (isValid, result, error) =
        await _validateFixtureTypeMappingFilePath(file.path);

    setState(() {
      _fixtureTypeMappingFilePath = file.path;
      _isFixtureTypeMappingFilePathValid = isValid;
    });

    if (isValid == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message: error ??
              'An unknown error occurred while reading the fixture type mapping file'));
    }

    widget.onFixtureMappingFilePathChanged(file.path);
  }

  void _handleFixtureDatabaseSelect() async {
    final file = await openFile(
      confirmButtonText: "Select",
      acceptedTypeGroups: kExcelFileTypes,
      initialDirectory: _fixtureDatabaseSpreadsheetFilePath.isNotEmpty
          ? p.dirname(_fixtureDatabaseSpreadsheetFilePath)
          : null,
    );

    if (file == null) {
      return;
    }

    final (isValid, result, error) =
        await _validateFixtureDatabaseSpreadsheetFilePath(file.path);

    setState(() {
      _fixtureDatabaseSpreadsheetFilePath = file.path;
      _isFixtureDatabaseSpreadsheetFilePathValid = isValid;
    });

    if (isValid == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(genericErrorSnackBar(
          context: context,
          message: error ??
              'An unknown error occurred while reading the Fixture Database'));
    }

    widget.onFixtureDatabaseFilePathChanged(file.path);
  }

  void _handlePatchFileSelect() async {
    final file = await openFile(
        confirmButtonText: 'Import',
        acceptedTypeGroups: switch (_selectedSource) {
          PatchSource.excel => kExcelFileTypes,
          PatchSource.grandMA2XML => kXmlFileTypes,
          PatchSource.mvr => kMvrFileTypes,
        });

    if (file == null) {
      return;
    }

    setState(() => _targetFilePath = file.path);
  }

  SizedBox _buildSourceSelector(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patch Type', style: Theme.of(context).textTheme.titleSmall),
              const Divider(),
              RadioListTile<PatchSource>(
                value: PatchSource.mvr,
                groupValue: _selectedSource,
                onChanged: (value) => setState(() {
                  _targetFilePath = '';
                  _selectedSource = value!;
                }),
                title: const Text("MVR File"),
                subtitle: const Text('.mvr'),
              ),
              RadioListTile<PatchSource>(
                value: PatchSource.grandMA2XML,
                groupValue: _selectedSource,
                onChanged: (value) => setState(() {
                  _targetFilePath = '';
                  _selectedSource = value!;
                }),
                title: const Text("GrandMA2 Fixture Layers"),
                subtitle: const Text('.xml'),
              ),
              RadioListTile<PatchSource>(
                value: PatchSource.excel,
                groupValue: _selectedSource,
                onChanged: (value) => setState(() {
                  _targetFilePath = '';
                  _selectedSource = value!;
                }),
                title: const Text("Excel Spreadsheet"),
                subtitle: const Text('.xls, .xlsx'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
