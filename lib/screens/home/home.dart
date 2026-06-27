import 'package:sidekick/containers/breakout_cabling_container.dart';
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
import 'package:sidekick/containers/racks_container.dart';
import 'package:sidekick/global_keys.dart';
import 'package:sidekick/screens/the_lab.dart';
import 'package:sidekick/view_models/home_view_model.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class Home extends StatefulWidget {
  final HomeViewModel vm;

  const Home({Key? key, required this.vm}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

final PageStorageBucket _pageStorageBucket = PageStorageBucket();

class _HomeState extends State<Home> {
  int _tabIndex = 0;

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
      child: Scaffold(
          key: homeScaffoldKey,
          headers: [
            // Navigation Bar
            NavigationBar(
              onSelected: (key) =>
                  setState(() => _tabIndex = (key as ValueKey<int>).value),
              selectedKey: ValueKey(_tabIndex),
              expanded: false,
              labelType: NavigationLabelType.all,
              alignment: NavigationBarAlignment.start,
              children: const [
                _NavigationItem(
                  index: 0,
                  label: Text('File'),
                  child: Icon(Icons.folder),
                ),
                _NavigationItem(
                  index: 1,
                  label: Text('Fixtures'),
                  child: Icon(Icons.lightbulb),
                ),
                _NavigationItem(
                  index: 2,
                  label: Text('Patch'),
                  child: Icon(Icons.electric_bolt),
                ),
                _NavigationItem(
                  index: 3,
                  label: Text('Racks'),
                  child: Icon(Icons.dns),
                ),
                _NavigationItem(
                  index: 4,
                  label: Text('Hoists'),
                  child: Icon(Icons.construction),
                ),
                _NavigationItem(
                  index: 5,
                  label: Text('Looms'),
                  child: Icon(Icons.cable),
                ),
                _NavigationItem(
                  index: 6,
                  label: Text('Breakout Cabling'),
                  child: Icon(Icons.auto_graph),
                ),
                _NavigationItem(
                  index: 7,
                  label: Text('Locations'),
                  child: Icon(Icons.location_pin),
                ),
                _NavigationItem(
                  index: 8,
                  label: Text('Fixture Types'),
                  child: Icon(Icons.light),
                ),
                _NavigationItem(
                  index: 9,
                  label: Text('Export'),
                  child: Icon(Icons.save_alt),
                ),
                _NavigationItem(
                  index: 10,
                  label: Text('Diff'),
                  child: Icon(Icons.difference),
                ),
                _NavigationItem(
                  index: 11,
                  label: Text('Lab'),
                  child: Icon(Icons.build),
                ),
                _NavigationItem(
                  index: 12,
                  label: Text("Diagnostics"),
                  child: Icon(Icons.bug_report),
                ),
              ],
            ),

            if (_tabIndex == 3)
              SizedBox(
                height: 48,
                child: NavigationBar(
                  labelType: NavigationLabelType.all,
                  selectedKey: ValueKey(widget.vm.racksTabIndex),
                  onSelected: (key) => widget.vm
                      .onRacksTabIndexChanged((key as ValueKey<int>).value),
                  expanded: false,
                  alignment: NavigationBarAlignment.start,
                  children: const [
                    NavigationItem(
                      key: ValueKey(0),
                      child: Text('Power'),
                    ),
                    NavigationItem(
                      key: ValueKey(1),
                      child: Text('Data'),
                    )
                  ],
                ),
              )
          ],
          child: switch (_tabIndex) {
            0 => const FileContainer(),
            1 => const FixtureTableContainer(),
            2 => const PowerPatchContainer(),
            3 => const RacksContainer(),
            4 => const HoistsContainer(),
            5 => const LoomsContainer(),
            6 => const BreakoutCablingContainer(),
            7 => const LocationsContainer(),
            8 => const FixtureTypesContainer(),
            9 => const ExportContainer(),
            10 => const DiffingScreenContainer(),
            11 => const TheLab(),
            12 => const DiagnosticsContainer(),
            _ => throw "Missing Switch clause for index $_tabIndex",
          }),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Widget label;
  const _NavigationItem({
    required this.index,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationItem(
      key: ValueKey(index),
      style: const ButtonStyle.muted(density: ButtonDensity.icon),
      selectedStyle: const ButtonStyle.fixed(density: ButtonDensity.icon),
      label: label,
      child: child,
    );
  }
}
