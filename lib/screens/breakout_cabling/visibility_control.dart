import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/redux/models/cable_visibility_model.dart';
import 'package:sidekick/widgets/hover_region.dart';

class VisibilityControl extends StatelessWidget {
  final CableVisibilityModel state;
  final void Function(CableVisibilityModel state) onVisibilityChanged;

  const VisibilityControl({
    super.key,
    required this.state,
    required this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return HoverRegionBuilder(builder: (context, isHovering) {
      return Opacity(
        opacity: isHovering ? 1 : 0.25,
        child: Card(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                child: const Text('Show All'),
                onPressed: () =>
                    onVisibilityChanged(const CableVisibilityModel.all()),
              ),
              const Divider(
                height: 24,
                child: Text('Power'),
              ),
              Checkbox(
                state: _resolveState(
                    state.powerState.contains(CableRunType.homeRun)),
                onChanged: (value) => onVisibilityChanged(
                    _updatePowerState(state, value, CableRunType.homeRun)),
                trailing: const Text('Home Runs'),
              ),
              const SizedBox(height: 8),
              Checkbox(
                state: _resolveState(
                    state.powerState.contains(CableRunType.fixtureRun)),
                onChanged: (value) => onVisibilityChanged(
                    _updatePowerState(state, value, CableRunType.fixtureRun)),
                trailing: const Text('Fixture Runs'),
              ),
              const SizedBox(height: 8),
              Checkbox(
                state:
                    _resolveState(state.powerState.contains(CableRunType.link)),
                onChanged: (value) => onVisibilityChanged(
                    _updatePowerState(state, value, CableRunType.link)),
                trailing: const Text('Links'),
              ),
              const Divider(height: 24, child: Text('Data')),
              Checkbox(
                state: _resolveState(
                    state.dataState.contains(CableRunType.homeRun)),
                onChanged: (value) => onVisibilityChanged(
                    _updateDataState(state, value, CableRunType.homeRun)),
                trailing: const Text('Home Runs'),
              ),
              const SizedBox(height: 8),
              Checkbox(
                state: _resolveState(
                    state.dataState.contains(CableRunType.fixtureRun)),
                onChanged: (value) => onVisibilityChanged(
                    _updateDataState(state, value, CableRunType.fixtureRun)),
                trailing: const Text('Fixture Runs'),
              ),
              const SizedBox(height: 8),
              Checkbox(
                state:
                    _resolveState(state.dataState.contains(CableRunType.link)),
                onChanged: (value) => onVisibilityChanged(
                    _updateDataState(state, value, CableRunType.link)),
                trailing: const Text('Links'),
              ),
            ],
          ),
        ),
      );
    });
  }

  CheckboxState _resolveState(bool value) {
    return value == true ? CheckboxState.checked : CheckboxState.unchecked;
  }

  CableVisibilityModel _updatePowerState(
      CableVisibilityModel existing, CheckboxState value, CableRunType type) {
    return existing.copyWith(
      powerState: value == CheckboxState.checked
          ? {...existing.powerState, type}
          : (existing.powerState.toSet()..remove(type)),
    );
  }

  CableVisibilityModel _updateDataState(
      CableVisibilityModel existing, CheckboxState value, CableRunType type) {
    return existing.copyWith(
      dataState: value == CheckboxState.checked
          ? {...existing.dataState, type}
          : (existing.dataState.toSet()..remove(type)),
    );
  }
}
