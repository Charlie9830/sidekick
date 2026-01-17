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
              onSelected: (index) => setState(() => _tabIndex = index),
              index: _tabIndex,
              expands: false,
              labelType: NavigationLabelType.all,
              alignment: NavigationBarAlignment.start,
              children: const [
                _NavigationItem(
                  label: Text('File'),
                  child: Icon(Icons.folder),
                ),
                _NavigationItem(
                  label: Text('Fixtures'),
                  child: Icon(Icons.lightbulb),
                ),
                _NavigationItem(
                  label: Text('Patch'),
                  child: Icon(Icons.electric_bolt),
                ),
                _NavigationItem(
                  label: Text('Racks'),
                  child: Icon(Icons.dns),
                ),
                _NavigationItem(
                  label: Text('Hoists'),
                  child: Icon(Icons.construction),
                ),
                _NavigationItem(
                  label: Text('Looms'),
                  child: Icon(Icons.cable),
                ),
                _NavigationItem(
                  label: Text('Locations'),
                  child: Icon(Icons.location_pin),
                ),
                _NavigationItem(
                  label: Text('Fixture Types'),
                  child: Icon(Icons.light),
                ),
                _NavigationItem(
                  label: Text('Export'),
                  child: Icon(Icons.save_alt),
                ),
                _NavigationItem(
                  label: Text('Diff'),
                  child: Icon(Icons.difference),
                ),
                _NavigationItem(
                  label: Text('Lab'),
                  child: Icon(Icons.build),
                ),
                _NavigationItem(
                  label: Text("Diagnostics"),
                  child: Icon(Icons.bug_report),
                )
              ],
            ),
          ],
          child: switch (_tabIndex) {
            0 => const FileContainer(),
            1 => const FixtureTableContainer(),
            2 => const PowerPatchContainer(),
            3 => const RacksContainer(),
            4 => const HoistsContainer(),
            5 => const LoomsContainer(),
            6 => const LocationsContainer(),
            7 => const FixtureTypesContainer(),
            8 => const ExportContainer(),
            9 => const DiffingScreenContainer(),
            10 => const TheLab(),
            11 => const DiagnosticsContainer(),
            _ => throw "Missing Switch clause for index $_tabIndex",
          }),
    );
  }
}

class _NavigationItem extends StatelessWidget implements NavigationBarItem {
  final Widget child;
  final Widget label;
  const _NavigationItem({
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationItem(
      style: const ButtonStyle.muted(density: ButtonDensity.icon),
      selectedStyle: const ButtonStyle.fixed(density: ButtonDensity.icon),
      label: label,
      child: child,
    );
  }

  @override
  bool get selectable => true;
}
