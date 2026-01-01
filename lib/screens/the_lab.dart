import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/state/app_state.dart';

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
                headers: [
                  AppBar(
                    title: Text('The Lab'),
                    backgroundColor: Colors.orange.shade600,
                  ),
                ],
                child: Center(
                    child: Text(
                  'Test Text',
                  style: Theme.of(context).typography.bold,
                ))));
  }
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
