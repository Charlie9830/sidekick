import 'package:flutter/material.dart';
import 'package:sidekick/view_models/looms_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class Looms extends StatelessWidget {
  final LoomsViewModel vm;
  const Looms({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: vm.rowVms.length,
      itemBuilder: (context, index) {
        final rowVm = vm.rowVms[index];

        return Card(
            child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(rowVm.loom.name), Text(rowVm.locationName)],
            ),
            ...rowVm.loom.children.map((cable) => Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: PropertyField()),
                    Text(cable.type.name),
                  ],
                ))
          ],
        ));
      },
    );
  }
}
