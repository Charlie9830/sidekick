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

sealed class OutletBase {
  final String uid;
  final int number;

  OutletBase({
    required this.uid,
    required this.number,
  });

  OutletBase copyWith();
}

sealed class MultiOutletBase extends OutletBase {
  final bool isDetached;

  MultiOutletBase({
    required super.uid,
    required super.number,
    required this.isDetached,
  });

  @override
  MultiOutletBase copyWith();
}

class SingleDataOutlet extends OutletBase {
  final String name;

  SingleDataOutlet({
    required super.uid,
    required super.number,
    required this.name,
  });

  @override
  OutletBase copyWith({
    String? uid,
    int? number,
    String? name,
  }) {
    return SingleDataOutlet(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      number: number ?? this.number,
    );
  }
}

class MultiDataOutlet extends MultiOutletBase {
  final String name;

  MultiDataOutlet({
    required super.uid,
    required super.number,
    required this.name,
    required super.isDetached,
  });

  @override
  MultiOutletBase copyWith({
    String? uid,
    int? number,
    String? name,
    bool? isDetached,
  }) {
    return MultiDataOutlet(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      number: number ?? this.number,
      isDetached: isDetached ?? this.isDetached,
    );
  }
}

void doStuff() {}

OutletBase assertNumber<T extends OutletBase>(T source) {
  return switch (source) {
    SingleDataOutlet o => o.copyWith(number: 0),
    MultiDataOutlet o => o.copyWith(number: 0)
  };
}
