import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/slotted_list/attempt2.dart';

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
      builder: (context, viewModel) {
        return Scaffold(
          headers: [
            AppBar(
              title: const Text('The Lab'),
              backgroundColor: Colors.emerald,
              trailing: [
                PrimaryButton(
                  child: const Text('Debug Action'),
                  onPressed: () =>
                      viewModel.store.dispatch(debugButtonPressed()),
                )
              ],
            ),
          ],
          child: ListTester(),
        );
      },
    );
  }
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
