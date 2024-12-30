import 'package:flutter/material.dart';
import 'package:sidekick/containers/data_patch_container.dart';
import 'package:sidekick/containers/diffing_container.dart';
import 'package:sidekick/containers/export_container.dart';
import 'package:sidekick/containers/file_container.dart';
import 'package:sidekick/containers/fixture_table_container.dart';
import 'package:sidekick/containers/fixture_types_container.dart';
import 'package:sidekick/containers/locations_container.dart';
import 'package:sidekick/containers/looms_container.dart';
import 'package:sidekick/containers/power_patch_container.dart';
import 'package:sidekick/global_keys.dart';
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
      length: 9,
      initialIndex: 0,
      child: Scaffold(
        key: homeScaffoldKey,
        appBar: AppBar(
          title: const Text("It's Just a Phase!"),
          primary: true,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  icon: Icon(Icons.folder),
                  child: Text('File'),
                ),
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
                Tab(
                  icon: Icon(Icons.cable),
                  child: Text('Looms'),
                ),
                Tab(
                  icon: Icon(Icons.location_pin),
                  child: Text('Locations'),
                ),
                Tab(
                  icon: Icon(Icons.light),
                  child: Text('Fixture Types'),
                ),
                Tab(
                  icon: Icon(Icons.save_alt),
                  child: Text('Export'),
                ),
                Tab(
                  icon: Icon(Icons.difference),
                  child: Text('Diff'),
                )
              ]),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            FileContainer(),
            FixtureTableContainer(),
            PowerPatchContainer(),
            DataPatchContainer(),
            LoomsContainer(),
            LocationsContainer(),
            FixtureTypesContainer(),
            ExportContainer(),
            DiffingContainer(),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => widget.vm.onDebugAction(),
              backgroundColor: Colors.blueGrey,
              child: const Icon(Icons.bug_report),
            ),
            const SizedBox(height: 24),
            FloatingActionButton(
              onPressed: () => widget.vm.onAppInitialize(),
              child: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
