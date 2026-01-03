import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/titled_card.dart';

import 'package:sidekick/view_models/diagnostics_view_model.dart';

class DiagnosticsScreen extends StatelessWidget {
  final DiagnosticsViewModel vm;
  const DiagnosticsScreen({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryButton(
              onPressed: vm.onDebugAction, child: const Text("Debug Action")),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  TitledCard(
                    title: 'Hoist Multi Outlets',
                    child: Column(
                      children: vm.appState.fixtureState.hoistMultis.values
                          .map((multi) => Text(
                              '${multi.name}:   ${multi.number},   ${multi.locationId}'))
                          .toList(),
                    ),
                  ),
                  TitledCard(
                    title: 'Power Racks',
                    child: Column(
                      children: vm.appState.fixtureState.powerRacks.values
                          .map((rack) => Text(
                              '${rack.name}     index: ${rack.rackIndex}     Outlet Count: ${rack.outletSlots.qty}    parentSystemId: ${rack.parentSystemId}'))
                          .toList(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
