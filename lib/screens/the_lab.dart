import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/locations/multi_color_chit.dart';

class TheLab extends StatefulWidget {
  const TheLab({super.key});

  @override
  State<TheLab> createState() => _TheLabState();
}

class _TheLabState extends State<TheLab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('The Lab'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MultiColorChit(
                  height: 16,
                  value: LabelColorModel(colors: [
                    NamedColors.red,
                  ])),
              VerticalDivider(),
              MultiColorChit(
                  height: 16,
                  value: LabelColorModel(colors: [
                    NamedColors.red,
                    NamedColors.white,
                  ])),
              VerticalDivider(),
              MultiColorChit(
                  height: 16,
                  value: LabelColorModel(colors: [
                    NamedColors.red,
                    NamedColors.white,
                    NamedColors.blue,
                  ])),
            ],
          ),
        ));
  }
}
