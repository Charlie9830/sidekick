import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';

class Sidebar extends StatelessWidget {
  final BreakoutCablingViewModel vm;

  const Sidebar({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.builder(
        itemCount: vm.locationVms.length,
        itemBuilder: (context, index) {
          final item = vm.locationVms[index];
          return ShadListItem(
            key: ValueKey(item.location.uid),
            selected: item.location.uid == vm.selectedLocationId,
            title: Text(item.location.name),
            trailing: _TrussBreakToggle(locationVm: item),
            onTap: () => item.onSelect(),
          );
        },
      ),
    );
  }
}

/// Trailing per-row control signalling and toggling whether cables in a
/// location break where they cross a truss join.
///
/// The default (breaking) state is kept quiet so the eye catches the
/// exceptions: locations set to run cables through joins show a loud accent
/// badge instead.
class _TrussBreakToggle extends StatelessWidget {
  final LocationViewModel locationVm;

  const _TrussBreakToggle({required this.locationVm});

  @override
  Widget build(BuildContext context) {
    final breaks = locationVm.location.breakAtTrussJoins;

    return SimpleTooltip(
      message: breaks
          ? 'Cables break at truss joins'
          : 'Cables run through truss joins (no break)',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => locationVm.onSetBreakAtTrussJoins(!breaks),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              breaks ? Icons.content_cut : Icons.block,
              size: 12,
              color: breaks
                  ? Theme.of(context).colorScheme.mutedForeground
                  : SidekickColors.warning,
            ),
          ),
        ),
      ),
    );
  }
}
