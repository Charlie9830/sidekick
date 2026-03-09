import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/data_racks.dart';
import 'package:sidekick/screens/racks/power_racks.dart';
import 'package:sidekick/simple_tooltip.dart';

import 'package:sidekick/toolbar_body_scaffold.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';
import 'package:sidekick/widgets/toolbar.dart';

class Racks extends StatefulWidget {
  final RacksScreenViewModel viewModel;
  const Racks({super.key, required this.viewModel});

  @override
  State<Racks> createState() => _RacksState();
}

class _RacksState extends State<Racks> {
  Set<String> _selectedPowerMultiPlacedIds = {};
  Set<String> _selectedDataPatchPlacedIds = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ToolbarBodyScaffold(
        toolbar: Toolbar(
            child: Row(
          children: [
            if (widget.viewModel.tabIndex == 0) // Power Tab
              SimpleTooltip(
                message: 'Unpatch selected Power Multis',
                child: IconButton.destructive(
                  icon: const Icon(Icons.clear),
                  onPressed: _selectedPowerMultiPlacedIds.isNotEmpty
                      ? () {
                          widget.viewModel.onUnpatchPowerMultis(
                              _selectedPowerMultiPlacedIds);
                        }
                      : null,
                ),
              ),
            if (widget.viewModel.tabIndex == 1) // Power Tab
              SimpleTooltip(
                message: 'Unpatch selected Data Outlets',
                child: IconButton.destructive(
                  icon: const Icon(Icons.clear),
                  onPressed: _selectedDataPatchPlacedIds.isNotEmpty
                      ? () {
                          widget.viewModel.onUnpatchDataOutlets(
                              _selectedDataPatchPlacedIds);
                        }
                      : null,
                ),
              ),
          ],
        )),
        body: switch (widget.viewModel.tabIndex) {
          0 => PowerRacks(
              viewModel: widget.viewModel,
              onPowerMultiSelectionChanged:
                  (selectedAvailabledIds, selectedPlacedIds) => setState(() {
                        _selectedPowerMultiPlacedIds = selectedPlacedIds;
                      })),
          1 => DataRacks(
              viewModel: widget.viewModel,
              onDataOutletSelectionChanged:
                  (selectedAvailableIds, selectedPlacedIds) => setState(() {
                _selectedDataPatchPlacedIds = selectedPlacedIds;
              }),
            ),
          _ => const Text('Unexpected Tab Index')
        });
  }
}
