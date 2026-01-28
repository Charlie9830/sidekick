import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/open_shad_sheet.dart';
import 'package:sidekick/screens/hoists/hoist_controller.dart';
import 'package:sidekick/view_models/hoists_view_model.dart';

class MotorControllerAssignment extends StatelessWidget {
  final HoistsViewModel viewModel;
  const MotorControllerAssignment({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final controllers = viewModel.hoistControllers;

    return ListView.builder(
        itemCount: controllers.length + 1,
        itemBuilder: (context, index) {
          if (controllers.isEmpty || index == controllers.length) {
            return _HoistControllerListTrailer(
                onAddButtonPressed: () => _handleAddButtonPressed(context));
          }

          return HoistController(viewModel: controllers[index]);
        });
  }

  void _handleAddButtonPressed(BuildContext context) async {
    final int? ways = await openShadSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text('Add Motor Controller').large,
            ),
            TextButton(
              child: const Text('8 way'),
              onPressed: () => Navigator.of(context).pop(8),
            ),
            TextButton(
              child: const Text('16 way'),
              onPressed: () => Navigator.of(context).pop(16),
            ),
            TextButton(
              child: const Text('32 way'),
              onPressed: () => Navigator.of(context).pop(32),
            ),
          ],
        ),
      ),
    );

    if (ways == null) {
      return;
    }

    viewModel.onAddMotorController(ways);
  }
}

class _HoistControllerListTrailer extends StatelessWidget {
  final void Function() onAddButtonPressed;

  const _HoistControllerListTrailer({
    required this.onAddButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton.secondary(
        onPressed: onAddButtonPressed,
        icon: const Icon(Icons.add),
        trailing: const Text('Add Motor Controller'),
      ),
    );
  }
}
