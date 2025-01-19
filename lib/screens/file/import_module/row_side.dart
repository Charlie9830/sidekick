import 'package:flutter/material.dart';
import 'package:sidekick/screens/file/import_module/cell_geometry.dart';

class RowSide extends StatelessWidget {
  final String fid;
  final bool hasErrors;
  final String fixtureType;
  final String location;
  final int universe;
  final int address;

  const RowSide({
    super.key,
    required this.fid,
    required this.hasErrors,
    required this.fixtureType,
    required this.location,
    required this.universe,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            SizedBox(
                width: CellGeometry.fixtureIdWidth,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fid),
                      if (hasErrors)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.warning,
                                color: Colors.redAccent, size: 16),
                          ],
                        ),
                      const VerticalDivider(),
                    ])),
            SizedBox(
                width: CellGeometry.fixtureTypeWidth,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fixtureType),
                      const VerticalDivider(),
                    ])),
            SizedBox(
                width: CellGeometry.locationWidth,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(location),
                      const VerticalDivider(),
                    ])),
            SizedBox(
                width: CellGeometry.universeWidth,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(universe.toString()),
                      const VerticalDivider(),
                    ])),
            SizedBox(
                width: CellGeometry.addressWidth,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(address.toString()),
                    ])),
          ],
        ),
      ],
    );
  }
}

class NoRowSide extends StatelessWidget {
  const NoRowSide({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('No Item');
  }
}
