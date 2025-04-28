import 'package:easy_stepper/easy_stepper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/file_type_groups.dart';
import 'package:sidekick/redux/models/dmx_address_model.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/screens/file/import_module/row_error_item.dart';
import 'package:sidekick/screens/file/import_module/select_file_control.dart';
import 'package:sidekick/view_models/import_manager_view_model.dart';
import 'package:path/path.dart' as p;

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

  @override
  void initState() {
    _selectionFocusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text('Import Manager'),
        actions: [
          Tooltip(
            message: widget.vm.importFilePath,
            child: Text(
              p.basename(widget.vm.importFilePath),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.vm.onRefreshButtonPressed,
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
                  activeStep: widget.vm.step,
                  enableStepTapping: false,
                  showLoadingAnimation: false,
                  defaultStepBorderType: BorderType.normal,
                  stepRadius: 32,
                  steps: const [
                    EasyStep(icon: Icon(Icons.file_open), title: 'Select File'),
                    EasyStep(icon: Icon(Icons.dry_cleaning), title: 'Validate'),
                    EasyStep(
                      icon: Icon(Icons.merge),
                      title: 'Merge',
                    )
                  ],
                ),
              )),
          Expanded(
              child: switch (widget.vm.step) {
            1 => SelectFileControl(
                fixtureDatabaseSpreadsheetFilePath:
                    widget.vm.fixtureDatabaseFilePath,
                fixtureTypeMappingFilePath: widget.vm.fixtureMappingFilePath,
                onFixtureTypesLoaded: (types) =>
                    setState(() => _fixtureTypes = types),
                onFixtureDatabaseFilePathChanged:
                    widget.vm.onFixtureDatabaseFilePathChanged,
                onFixtureMappingFilePathChanged:
                    widget.vm.onFixtureMappingFilePathChanged,
              ),
            _ => Text('No Content'),
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: widget.vm.onNextButtonPressed,
          label: const Text('Next'),
          icon: const Icon(Icons.arrow_circle_right)),
    );
  }

  Widget _buildErrorPane(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.zero)),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Errors and Warnings'),
            ),
          ),
        ),
        Expanded(
            child: ListView.builder(
          itemCount: widget.vm.rowErrors.length,
          itemBuilder: (context, index) =>
              RowErrorItem(value: widget.vm.rowErrors[index]),
        )),
      ],
    );
  }

  @override
  void dispose() {
    _selectionFocusNode.dispose();
    super.dispose();
  }
}
