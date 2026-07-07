import 'dart:io';

import 'package:excel_community/excel_community.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide IndexedSlot;
import 'package:sidekick/redux/models/export_error_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';
import 'package:sidekick/validate_export_data.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sidekick/classes/export_file_paths.dart';
import 'package:sidekick/excel/create_color_lookup_sheet.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/excel/create_breakout_cabling_sheet.dart';
import 'package:sidekick/excel/create_data_multi_sheet.dart';
import 'package:sidekick/excel/create_data_patch_sheet.dart';
import 'package:sidekick/excel/create_fixture_addressing_sheet.dart';
import 'package:sidekick/excel/create_fixture_info_sheet.dart';
import 'package:sidekick/excel/create_fixture_type_validation_sheet.dart';
import 'package:sidekick/excel/create_hoist_patch_sheet.dart';
import 'package:sidekick/excel/create_lighting_looms_sheet.dart';
import 'package:sidekick/excel/create_power_patch_sheet.dart';
import 'package:sidekick/generic_dialog/show_generic_dialog.dart';
import 'package:sidekick/redux/actions/sync_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/toasts.dart';

ThunkAction<AppState> performExportDataValidation() {
  return (Store<AppState> store) async {
    store.dispatch(SetIsValidatingExportData(true));
    final result = await _validateExportData(store.state.fixtureState);
    store.dispatch(SetExportErrors(result));
  };
}

ThunkAction<AppState> chooseExportDirectory(BuildContext context) {
  return (Store<AppState> store) async {
    final lastUsedExportDirectory =
        store.state.fileState.projectMetadata.lastUsedExportDirectory.isNotEmpty
        ? store.state.fileState.projectMetadata.lastUsedExportDirectory
        : store.state.fileState.lastUsedProjectDirectory;

    final lastUsedExportDirectoryExists = await Directory(
      lastUsedExportDirectory,
    ).exists();

    final pathResult = await getDirectoryPath(
      initialDirectory:
          lastUsedExportDirectoryExists && lastUsedExportDirectory.isNotEmpty
          ? lastUsedExportDirectory
          : null,
    );

    if (pathResult == null) {
      return;
    }

    store.dispatch(SetLastUsedExportDirectory(pathResult));
  };
}

ThunkAction<AppState> export(BuildContext context) {
  return (Store<AppState> store) async {
    final outputPaths = ExportFilePaths(
      directoryPath:
          store.state.fileState.projectMetadata.lastUsedExportDirectory,
      projectName: store.state.fileState.projectMetadata.projectName,
      excelFileExtension: '.xlsx',
    );

    if (await outputPaths.parentDirectoryExists == false) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'Parent Directory could not be found',
          subtitle: 'Have you selected an export directory?',
        );
      }
      return;
    }
    final existingFileNames = await outputPaths.getAlreadyExistingFileNames();

    if (existingFileNames.isNotEmpty) {
      if (context.mounted) {
        final dialogResult = await showGenericDialog(
          context: context,
          title: 'Overwrite existing files',
          message:
              'If you proceed, the following files will be overwritten.\n${existingFileNames.join('\n')}',
          affirmativeText: 'Overwrite',
          destructiveAffirmative: true,
          declineText: 'Cancel',
        );

        if (dialogResult == null || dialogResult == false) {
          return;
        }
      }
    }

    store.dispatch(SetIsValidatingExportData(true));
    final validationResult = await _validateExportData(
      store.state.fixtureState,
    );

    store.dispatch(SetExportErrors(validationResult));

    if (validationResult.isNotEmpty) {
      if (context.mounted) {
        final dialogResult = await showGenericDialog(
          context: context,
          title: 'Project contains Errors',
          message:
              'Your project contains errors, are you sure you want to export?',
          affirmativeText: 'Export',
          declineText: 'Cancel',
        );

        if (dialogResult == null || dialogResult == false) {
          return;
        }
      }
    }

    final referenceDataExcel = Excel.createExcel();
    createPowerPatchSheet(
      excel: referenceDataExcel,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      powerRackTypes: store.state.fixtureState.powerRackTypes,
      powerRacks: store.state.fixtureState.powerRacks,
      fixtureTypePools: store.state.fixtureState.fixtureTypePools,
    );

    createColorLookupSheet(
      excel: referenceDataExcel,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      locations: store.state.fixtureState.locations,
    );

    createFixtureTypeValidationSheet(
      excel: referenceDataExcel,
      fixtures: store.state.fixtureState.fixtures,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      powerMultis: store.state.fixtureState.powerMultiOutlets,
      fixtureTypePools: store.state.fixtureState.fixtureTypePools,
    );

    createDataPatchSheet(
      excel: referenceDataExcel,
      dataOutlets: store.state.fixtureState.dataPatches.values,
      locations: store.state.fixtureState.locations,
      cables: store.state.fixtureState.cables,
      dataRackTypes: store.state.fixtureState.dataRackTypes,
      dataRacks: store.state.fixtureState.dataRacks,
    );

    createDataMultiSheet(
      excel: referenceDataExcel,
      dataOutlets: store.state.fixtureState.dataPatches,
      locations: store.state.fixtureState.locations,
      cables: store.state.fixtureState.cables,
      dataMultis: store.state.fixtureState.dataMultis,
      dataRacks: store.state.fixtureState.dataRacks,
    );

    createBreakoutCablingSheet(
      excel: referenceDataExcel,
      locations: store.state.fixtureState.locations,
      cableGraph: buildCableGraph(
        fixtures: store.state.fixtureState.fixtures,
        fixtureTypes: store.state.fixtureState.fixtureTypes,
        powerMultis: store.state.fixtureState.powerMultiOutlets,
        cables: store.state.fixtureState.cables,
        locations: store.state.fixtureState.locations,
        dataMultis: store.state.fixtureState.dataMultis,
        dataPatches: store.state.fixtureState.dataPatches,
        trusses: store.state.fixtureState.trusses,
      ),
    );

    referenceDataExcel.delete('Sheet1');

    final loomsExcel = Excel.createExcel();

    createLoomsSheet(excel: loomsExcel, store: store);

    loomsExcel.delete('Sheet1');

    final addressingExcel = Excel.createExcel();

    createFixtureAddressingSheet(
      fixtures: store.state.fixtureState.fixtures.values.toList(),
      locations: store.state.fixtureState.locations,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      excel: addressingExcel,
      projectName: store.state.fileState.projectMetadata.projectName,
    );

    final fixtureInfoExcel = Excel.createExcel();

    createFixtureInfoSheet(
      fixtures: store.state.fixtureState.fixtures.values.toList(),
      locations: store.state.fixtureState.locations,
      fixtureTypes: store.state.fixtureState.fixtureTypes,
      excel: fixtureInfoExcel,
      projectName: store.state.fileState.projectMetadata.projectName,
    );

    final hoistPatchExcel = Excel.createExcel();

    createHoistPatchSheet(excel: hoistPatchExcel, store: store);
    hoistPatchExcel.delete('Sheet1');

    final referenceDataBytes = referenceDataExcel.save();
    final loomsBytes = loomsExcel.save();
    final powerPatchTemplateBytes = await rootBundle.load(
      'assets/excel/prg_power_patch.xlsx',
    );
    final dataPatchTemplateBytes = await rootBundle.load(
      'assets/excel/prg_data_patch.xlsx',
    );
    final addressingBytes = addressingExcel.save();
    final fixtureInfoBytes = fixtureInfoExcel.save();
    final hoistPatchBytes = hoistPatchExcel.save();

    if (referenceDataBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'Excel output error',
          subtitle: 'An error occurred writing reference data',
        );
      }

      return;
    }

    if (loomsBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'Excel output error',
          subtitle: 'An error occurred writing looms data',
        );
      }

      return;
    }

    if (hoistPatchBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'Excel output error',
          subtitle: 'An error occurred writing hoist data',
        );
      }

      return;
    }

    if (addressingBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'Excel output error',
          subtitle: 'An error occurred writing fixture addressing data',
        );
      }

      return;
    }

    if (fixtureInfoBytes == null) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'Excel output error',
          subtitle: 'An error occurred writing fixture info data',
        );
      }

      return;
    }

    final fileWrites = [
      File(outputPaths.referenceDataPath).writeAsBytes(referenceDataBytes),
      File(outputPaths.loomsPath).writeAsBytes(loomsBytes),
      File(
        outputPaths.powerPatchPath,
      ).writeAsBytes(powerPatchTemplateBytes.buffer.asUint8List()),
      File(
        outputPaths.dataPatchPath,
      ).writeAsBytes(dataPatchTemplateBytes.buffer.asUint8List()),
      File(outputPaths.addressesPath).writeAsBytes(addressingBytes),
      File(outputPaths.fixtureInfoPath).writeAsBytes(fixtureInfoBytes),
      File(outputPaths.hoistPatchPath).writeAsBytes(hoistPatchBytes),
    ];

    try {
      await Future.wait(fileWrites);
    } catch (e) {
      if (context.mounted) {
        showGenericErrorToast(
          context: context,
          title: 'Export error',
          subtitle: '1 or more files failed to export',
        );

        return;
      }
    }

    if (context.mounted) {
      showGenericSuccessToast(
        context: context,
        title: 'Export finished successfully',
      );
    }

    if (store.state.navstate.openAfterExport == true) {
      await launchUrl(Uri.file(outputPaths.powerPatchPath));
      await launchUrl(Uri.file(outputPaths.dataPatchPath));
      await launchUrl(Uri.file(outputPaths.loomsPath));
      await launchUrl(Uri.file(outputPaths.addressesPath));
      await launchUrl(Uri.file(outputPaths.hoistPatchPath));
    }
  };
}

Future<List<ExportErrorModel>> _validateExportData(FixtureState state) async {
  return await compute<FixtureState, List<ExportErrorModel>>(
    (message) => validateExportData(message),
    state,
  );
}
