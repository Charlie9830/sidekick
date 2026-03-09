import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/screens/racks/data_rack.dart';
import 'package:sidekick/view_models/racks_screen_view_model.dart';

class DataRacksAssignment extends StatelessWidget {
  final RacksScreenViewModel viewModel;

  const DataRacksAssignment({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final racks = viewModel.dataRacks;

    final addRackButton =
        _DataRackListTrailer(onAddButtonPressed: viewModel.onAddDataRack);

    if (racks.isEmpty) {
      return addRackButton;
    }

    return ListView.builder(
      itemCount: racks.length + 1,
      itemBuilder: (context, index) {
        if (index == racks.length) {
          return addRackButton;
        }

        final rackVm = racks[index];

        return DataRack(
          viewModel: rackVm,
        );
      },
    );
  }
}

class _DataRackListTrailer extends StatelessWidget {
  final void Function() onAddButtonPressed;

  const _DataRackListTrailer({
    required this.onAddButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton.secondary(
        onPressed: onAddButtonPressed,
        icon: const Icon(Icons.add),
        trailing: const Text('Add Data Rack'),
      ),
    );
  }
}
