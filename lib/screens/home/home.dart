import 'package:flutter/material.dart';
import 'package:sidekick/containers/diagnostics_container.dart';
import 'package:sidekick/containers/export_container.dart';
import 'package:sidekick/containers/file_container.dart';
import 'package:sidekick/containers/fixture_table_container.dart';
import 'package:sidekick/containers/fixture_types_container.dart';
import 'package:sidekick/containers/hoists_container.dart';
import 'package:sidekick/containers/locations_container.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/containers/looms_container.dart';
import 'package:sidekick/containers/power_patch_container.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/screens/the_lab.dart';
import 'package:sidekick/view_models/home_view_model.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

class Home extends StatefulWidget {
  final HomeViewModel vm;

  const Home({Key? key, required this.vm}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

final PageStorageBucket _pageStorageBucket = PageStorageBucket();

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();

    // Initialize App
    widget.vm.onAppInitialize();
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: _pageStorageBucket,
      child: DefaultTabController(
        animationDuration: Duration.zero,
        length: 12,
        initialIndex: 0,
        child: shad.DrawerOverlay(
          child: Scaffold(
            key: homeScaffoldKey,
            appBar: AppBar(
              title: Text("Phase",
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontFamily: "Orbitron", fontWeight: FontWeight.bold)),
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
                      icon: Icon(Icons.dns),
                      child: Text('Racks'),
                    ),
                    Tab(
                      icon: Icon(Icons.construction),
                      child: Text('Hoists'),
                    ),
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
                    ),
                    Tab(
                      icon: Icon(Icons.build),
                      child: Text('Lab'),
                    ),
                    Tab(
                      icon: Icon(Icons.bug_report),
                      child: Text("Diagnostics"),
                    )
                  ]),
            ),
            body: const TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                FileContainer(),
                FixtureTableContainer(),
                PowerPatchContainer(),
                Text('Racks'),
                HoistsContainer(),
                LoomsContainer(),
                LocationsContainer(),
                FixtureTypesContainer(),
                ExportContainer(),
                DiffingScreenContainer(),
                TheLab(),
                DiagnosticsContainer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
