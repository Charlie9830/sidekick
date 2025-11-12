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
  @override
  void initState() {
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

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
