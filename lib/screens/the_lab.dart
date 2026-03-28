// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:sidekick/redux/actions/async_actions.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/widgets/property_field.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  String _value = '';

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
            child: Center(
                child: Column(
              spacing: 28,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_value),
                SizedBox(
                  width: 200,
                  child: PropertyField(
                    value: _value,
                    onBlur: (newValue) => setState(() => _value = newValue),
                  ),
                ),
              ],
            )));
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class Item {
  final String uid;
  final String name;

  Item(this.uid) : name = uid;
}

class ItemContainer {
  final String uid;
  final String name;
  final List<ItemAssignmentReference> slots;

  ItemContainer({
    required this.uid,
    required this.name,
    required this.slots,
  });

  ItemContainer copyWith({
    String? uid,
    String? name,
    List<ItemAssignmentReference>? slots,
  }) {
    return ItemContainer(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      slots: slots ?? this.slots,
    );
  }
}

class ItemAssignmentReference {
  final int index;
  final String itemId;

  ItemAssignmentReference({
    required this.index,
    required this.itemId,
  });
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
