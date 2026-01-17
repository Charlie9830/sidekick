import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/drag_proxy/drag_proxy.dart';
import 'package:sidekick/redux/state/app_state.dart';
import 'package:sidekick/slotted_list/slotted_list.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  Map<String, SlotItem<String>> items = {
    'one': SlotItem<String>(data: 'Item 1', id: 'one', associatedData: []),
    'two': SlotItem<String>(data: 'Item 2', id: 'two', associatedData: []),
    'three': SlotItem<String>(data: 'Item 3', id: 'three', associatedData: []),
    'four': SlotItem<String>(data: 'Item 4', id: 'four', associatedData: []),
    'five': SlotItem<String>(data: 'Item 5', id: 'five', associatedData: []),
  };

  Map<int, SlotItem<String>> assignments = {
    0: SlotItem<String>(data: 'Item 1', id: 'one', associatedData: []),
  };

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
              title: const Text('The Lab'),
              backgroundColor: Colors.orange.shade600,
            ),
          ],
          child: SlotListController(
            child: DragProxyController(
              child: Row(
                children: [
                  SizedBox(
                    width: 400,
                    child: Card(
                      child: Column(
                        children: items.values
                            .map((item) => TestItem(item.data))
                            .toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SlotList(
                      slotCount: 16,
                      items: assignments
                          .map((index, value) => MapEntry(index, value)),
                      occupiedBuilder: (context, index, itemId) =>
                          Content(index: index, title: items[itemId]!.data),
                      vacantBuilder: (context, index) =>
                          Content.empty(index: index),
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}

class Content extends StatelessWidget {
  final int index;
  final String title;

  const Content({super.key, required this.index, required this.title});

  const Content.empty({super.key, required this.index}) : title = '---';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: EdgeInsets.only(top: 4.0, left: 8.0),
        child: Card(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(index.toString(),
                  style: Theme.of(context)
                      .typography
                      .mono
                      .copyWith(backgroundColor: Colors.gray.shade800)),
              const VerticalDivider(
                width: 24,
                endIndent: 0,
              ),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

class TestItem extends StatelessWidget {
  final String title;

  const TestItem(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text(title),
    );
  }
}

class LabViewModel {
  final Store<AppState> store;

  LabViewModel({
    required this.store,
  });
}
