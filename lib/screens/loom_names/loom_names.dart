import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/power_outlet_model.dart';
import 'package:sidekick/screens/loom_names/location_tile.dart';
import 'package:sidekick/view_models/loom_names_view_model.dart';

class LoomNames extends StatelessWidget {
  final LoomNamesViewModel vm;
  const LoomNames({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text("Hello. I'm not implemented");
  }
}
