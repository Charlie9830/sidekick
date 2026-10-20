import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/widgets/rig_viewer/camera/rig_camera_state.dart';

/// What a left-button drag does, as the grandMA3 3D window's touch modes.
enum RigToolMode {
  select('Select', 'Click fixtures', LucideIcons.mousePointer2),
  move('Move', 'Slide the camera without turning it', LucideIcons.move),
  rotateCenter(
    'Rotate Center',
    'Orbit around the centre of the view',
    LucideIcons.rotate3d,
  ),
  zoom('Zoom', 'Drag up or down to zoom', LucideIcons.zoomIn),
  rotateSelection(
    'Rotate Selection',
    'Orbit around the selected fixtures',
    LucideIcons.orbit,
  );

  const RigToolMode(this.label, this.hint, this.icon);

  final String label;
  final String hint;
  final IconData icon;
}

/// The viewer's left-hand tool strip, in the console's order: touch modes,
/// then Fit / Fit Selected, the view presets and the display toggles.
class RigToolBar extends StatelessWidget {
  final RigToolMode mode;
  final ValueChanged<RigToolMode> onModeChanged;
  final VoidCallback onFit;

  /// Null when nothing is selected, which disables the button.
  final VoidCallback? onFitSelected;

  final ValueChanged<RigViewPreset> onPreset;
  final bool showLabels;
  final ValueChanged<bool> onShowLabelsChanged;
  final bool showConnectors;
  final ValueChanged<bool> onShowConnectorsChanged;

  const RigToolBar({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onFit,
    required this.onFitSelected,
    required this.onPreset,
    required this.showLabels,
    required this.onShowLabelsChanged,
    required this.showConnectors,
    required this.onShowConnectorsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final tool in RigToolMode.values)
            _ToolButton(
              icon: tool.icon,
              tooltip: '${tool.label} — ${tool.hint}',
              active: tool == mode,
              onPressed: () => onModeChanged(tool),
            ),
          const Divider(),
          _ToolButton(
            icon: LucideIcons.maximize,
            tooltip: 'Fit — frame the whole rig (F)',
            onPressed: onFit,
          ),
          _ToolButton(
            icon: LucideIcons.scanSearch,
            tooltip: 'Fit Selected — frame the selection (Shift+F)',
            onPressed: onFitSelected,
          ),
          _PresetMenu(onPreset: onPreset),
          const Divider(),
          _ToolButton(
            icon: LucideIcons.tag,
            tooltip: showLabels ? 'Hide labels' : 'Show labels',
            active: showLabels,
            onPressed: () => onShowLabelsChanged(!showLabels),
          ),
          _ToolButton(
            icon: LucideIcons.plug,
            tooltip: showConnectors ? 'Hide connectors' : 'Show connectors',
            active: showConnectors,
            onPressed: () => onShowConnectorsChanged(!showConnectors),
          ),
        ],
      ),
    );
  }
}

/// A camera-angle picker: Top, Front, Back, Left, Right, Bottom and 3D.
class _PresetMenu extends StatelessWidget {
  final ValueChanged<RigViewPreset> onPreset;

  const _PresetMenu({required this.onPreset});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => _ToolButton(
        icon: LucideIcons.camera,
        tooltip: 'View presets',
        onPressed: () => showDropdown<void>(
          context: context,
          builder: (context) => DropdownMenu(
            children: [
              for (final preset in RigViewPreset.values)
                MenuButton(
                  onPressed: (_) => onPreset(preset),
                  child: Text(preset.label),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 16,
      color: active ? SidekickColors.rigSelection : null,
    );

    return Semantics(
      label: tooltip,
      button: true,
      selected: active,
      child: SimpleTooltip(
        message: tooltip,
        child: active
            ? IconButton.secondary(
                size: ButtonSize.small,
                icon: iconWidget,
                onPressed: onPressed,
              )
            : IconButton.ghost(
                size: ButtonSize.small,
                icon: iconWidget,
                onPressed: onPressed,
              ),
      ),
    );
  }
}
