import 'package:flutter/material.dart';
import 'package:sidekick/screens/file/import_module/cell_geometry.dart';
import 'package:sidekick/screens/file/import_module/table_header_card.dart';

class TableHeader extends StatelessWidget {
  const TableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const TableHeaderCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
              width: CellGeometry.fixtureIdWidth,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Fixture ID"),
                    VerticalDivider(),
                  ])),
          SizedBox(
              width: CellGeometry.fixtureTypeWidth,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Type"),
                    VerticalDivider(),
                  ])),
          SizedBox(
              width: CellGeometry.locationWidth,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Location"),
                    VerticalDivider(),
                  ])),
          SizedBox(
              width: CellGeometry.universeWidth,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Universe"),
                    VerticalDivider(),
                  ])),
          SizedBox(
              width: CellGeometry.addressWidth,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Address"),
                  ])),
        ],
      ),
    );
  }
}
