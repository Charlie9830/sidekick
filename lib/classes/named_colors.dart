import 'dart:ui';

import 'package:sidekick/redux/models/named_color_model.dart';

class NamedColors {
  static Map<NamedColorModel, String> names = {
    red: 'red',
    white: 'white',
    blue: 'blue',
    green: 'green',
    brown: 'brown',
    grey: 'grey',
    orange: 'orange',
    yellow: 'yellow',
    purple: 'purple',
    black: 'black',
    none: 'none',
  };

  static const NamedColorModel red =
      NamedColorModel(color: Color.fromARGB(255, 255, 0, 0), name: 'Red', defaultLength: 45);
  static const NamedColorModel white =
      NamedColorModel(color: Color.fromARGB(255, 255, 255, 255), name: 'White', defaultLength: 40);
  static const NamedColorModel blue =
      NamedColorModel(color: Color.fromARGB(255, 0, 0, 255), name: 'Blue', defaultLength: 35);
  static const NamedColorModel green =
      NamedColorModel(color: Color.fromARGB(255, 0, 255, 0), name: 'Green', defaultLength: 0);
  static const NamedColorModel brown =
      NamedColorModel(color: Color.fromARGB(255, 183, 88, 0), name: 'Brown', defaultLength: 25);
  static const NamedColorModel grey =
      NamedColorModel(color: Color.fromARGB(255, 128, 128, 128), name: 'Grey', defaultLength: 20);
  static const NamedColorModel orange =
      NamedColorModel(color: Color.fromARGB(255, 255, 100, 0), name: 'Orange', defaultLength: 30);
  static const NamedColorModel yellow =
      NamedColorModel(color: Color.fromARGB(255, 255, 255, 0), name: 'Yellow', defaultLength: 50);
  static const NamedColorModel purple =
      NamedColorModel(color: Color.fromARGB(255, 140, 0, 255), name: 'Purple', defaultLength: 0);

  static const NamedColorModel black =
      NamedColorModel(color: Color.fromARGB(255, 0, 0, 0), name: 'Black', defaultLength: 0);

  static const NamedColorModel none =
      NamedColorModel(color: Color.fromARGB(0, 0, 0, 0), name: 'None', defaultLength: 0);
}
