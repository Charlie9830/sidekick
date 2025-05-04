import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/excel/create_lighting_looms_sheet.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, LabViewModel>(
      converter: (store) => LabViewModel(
        store: store,
      ),
      builder: (context, viewModel) => Scaffold(
          appBar: AppBar(
            title: const Text('The Lab'),
            backgroundColor: Colors.red,
          ),
          body: Center(
              child: ElevatedButton(
                  onPressed: () => _generate(viewModel),
                  child: const Text('Generate')))),
    );
  }

  void _generate(LabViewModel vm) async {
    final excel = Excel.createExcel();

    createLightingLoomsSheet(
      excel: excel,
      store: vm.store,
    );

    final writtenFile =
        await File(p.join(Directory.systemTemp.path, 'labtest.xlsx'))
            .writeAsBytes(excel.save()!);

    await launchUrl(Uri.file(writtenFile.path));
  }
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
