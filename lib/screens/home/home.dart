import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/containers/power_patch_container.dart';
import 'package:sidekick/view_models/home_view_model.dart';

class Home extends StatefulWidget {
  final HomeViewModel vm;

  const Home({Key? key, required this.vm}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();

    // Initialize App
    widget.vm.onAppInitialize();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      animationDuration: Duration.zero,
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sidekick'),
          primary: true,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  icon: Icon(Icons.lightbulb),
                  child: Text('Fixtures'),
                ),
                Tab(
                  icon: Icon(Icons.electric_bolt),
                  child: Text('Patch'),
                ),
                Tab(
                    icon: Icon(Icons.settings_input_svideo),
                    child: Text('Patch')),
              ]),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFixtureTable(context),
            const PowerPatchContainer(),
            const Text('Data Patch'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => widget.vm.onAppInitialize(),
          child: const Icon(Icons.light),
        ),
      ),
    );
  }

  Widget _buildFixtureTable(BuildContext context) {
    const placeholderCell = DataCell(
      Text('-'),
    );

    return DataTable(
      columns: const [
        DataColumn(label: Text('Sequence #')),
        DataColumn(label: Text('Fixture #')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Amps')),
        DataColumn(
          label: Row(children: [
            Icon(Icons.electric_bolt, color: Colors.yellow, size: 16),
            const SizedBox(width: 4),
            Text('Multi'),
          ]),
        ),
        DataColumn(
          label: Row(children: [
            Icon(Icons.electric_bolt, color: Colors.yellow, size: 16),
            const SizedBox(width: 4),
            Text('Patch'),
          ]),
        ),
        DataColumn(
          label: Row(children: [
            Icon(Icons.settings_input_svideo, color: Colors.blue, size: 16),
            const SizedBox(width: 4),
            Text('Multi'),
          ]),
        ),
        DataColumn(
          label: Row(children: [
            Icon(Icons.settings_input_svideo, color: Colors.blue, size: 16),
            const SizedBox(width: 4),
            Text('Patch'),
          ]),
        ),
      ],
      rows: widget.vm.fixtures.values.mapIndexed((index, fixture) {
        return DataRow(cells: [
          DataCell(Text('${index + 1}')),
          DataCell(Text(fixture.fid.toString())),
          DataCell(
            Text(fixture.type.name),
          ),
          DataCell(
            Text(fixture.type.amps.toString()),
          ),
          placeholderCell, // Power Multi
          placeholderCell, // Power Patch
          placeholderCell, // Data Multi
          placeholderCell, // Data Patch
        ]);
      }).toList(),
    );
  }
}
