
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sidekick/redux/state/app_state.dart';

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
            body: ListView(
              children: const [
                OverlayTest(
                  child: Text("Hello"),
                ),
              ],
            )));
  }
}

class OverlayTest extends StatelessWidget {
  final Widget child;
  const OverlayTest({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(child: Container(color: Colors.purple.withAlpha(100)))
      ],
    );
  }
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
