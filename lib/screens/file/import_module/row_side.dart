import 'package:flutter/material.dart';
import 'package:sidekick/screens/file/import_module/cell_geometry.dart';

class RowSide extends StatelessWidget {
  final String fid;
  final bool hasErrors;
  final String fixtureType;
  final String location;
  final int universe;
  final int address;
  final bool fidChanged;
  final bool fixtureTypeChanged;
  final bool locationChanged;
  final bool universeChanged;
  final bool addressChanged;

  const RowSide({
    super.key,
    required this.fid,
    required this.hasErrors,
    required this.fixtureType,
    required this.location,
    required this.universe,
    required this.address,
    this.fidChanged = false,
    this.addressChanged = false,
    this.fixtureTypeChanged = false,
    this.locationChanged = false,
    this.universeChanged = false,
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
                      Text(fid,
                          style: _getPropertyTextStyle(context, fidChanged)),
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
                      Text(fixtureType,
                          style: _getPropertyTextStyle(
                              context, fixtureTypeChanged)),
                      const VerticalDivider(),
                    ])),
            SizedBox(
                width: CellGeometry.locationWidth,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(location,
                          style:
                              _getPropertyTextStyle(context, locationChanged)),
                      const VerticalDivider(),
                    ])),
            SizedBox(
                width: CellGeometry.universeWidth,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(universe.toString(),
                          style:
                              _getPropertyTextStyle(context, universeChanged)),
                      const VerticalDivider(),
                    ])),
            SizedBox(
                width: CellGeometry.addressWidth,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(address.toString(),
                          style:
                              _getPropertyTextStyle(context, addressChanged)),
                    ])),
          ],
        ),
      ],
    );
  }

  TextStyle _getPropertyTextStyle(
      BuildContext context, bool hasPropertyChanged) {
    return Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(color: hasPropertyChanged ? Colors.orangeAccent : null);
  }
}

class NoRowSide extends StatelessWidget {
  const NoRowSide({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('No Item');
  }
}
