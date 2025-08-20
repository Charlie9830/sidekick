import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/extension_methods/to_model_map.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/widgets/hover_region.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  late Map<String, LocationModel> _existingLocations;
  late Map<String, LocationModel> _incomingLocations;
  Map<String, String> _idMappings = {}; // Incoming ID, Existing ID

  @override
  void initState() {
    _existingLocations = [
      LocationModel(
        uid: 'existing 1',
        name: 'LX1',
        color: const LabelColorModel.none(),
      ),
      LocationModel(
        uid: 'existing 2',
        name: 'LX2',
        color: const LabelColorModel.none(),
      ),
      LocationModel(
        uid: 'existing 3',
        name: 'LX3',
        color: const LabelColorModel.none(),
      ),
      LocationModel(
        uid: 'existing 4',
        name: 'LX4',
        color: const LabelColorModel.none(),
      ),
    ].toModelMap();

    _incomingLocations = [
      // LocationModel(
      //   uid: 'incoming 1',
      //   name: 'T1',
      //   color: const LabelColorModel.none(),
      // ),
      LocationModel(
        uid: 'incoming 2',
        name: 'T1',
        color: const LabelColorModel.none(),
      ),
      LocationModel(
        uid: 'incoming 3',
        name: 'T2',
        color: const LabelColorModel.none(),
      ),
      LocationModel(
        uid: 'incoming 4',
        name: 'T3',
        color: const LabelColorModel.none(),
      ),
    ].toModelMap();
    super.initState();
  }

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
          body: const Text('The Lab')),
    );
  }
}

enum MergeAction {
  adoptExistingId,
  removeExisting,
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
