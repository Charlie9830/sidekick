import 'dart:ui';

import 'package:collection/collection.dart';

Color tryMatchLocationColor(String locationName) {
  final lookup = <RegExp, Color>{
    RegExp(r'red ', caseSensitive: false): const Color.fromARGB(255, 255, 0, 0),
    RegExp(r'white ', caseSensitive: false):
        const Color.fromARGB(255, 255, 255, 255),
    RegExp(r'blue ', caseSensitive: false):
        const Color.fromARGB(255, 0, 0, 255),
    RegExp(r'green ', caseSensitive: false):
        const Color.fromARGB(255, 0, 255, 0),
    RegExp(r'brown ', caseSensitive: false):
        const Color.fromARGB(255, 255, 145, 0),
    RegExp(r'SR ', caseSensitive: false):
        const Color.fromARGB(255, 255, 100, 0),
    RegExp(r'Stage Right ', caseSensitive: false):
        const Color.fromARGB(255, 255, 100, 0),
    RegExp(r'SL ', caseSensitive: false):
        const Color.fromARGB(255, 255, 255, 0),
    RegExp(r'Stage Left ', caseSensitive: false):
        const Color.fromARGB(255, 255, 255, 0),
    RegExp(r'DSL ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'DSC ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'DSR ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'MSL ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'MSC ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'MSR ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'USL ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'USC ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'USR ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'DS ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'MS ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
    RegExp(r'US ', caseSensitive: false):
        const Color.fromARGB(255, 128, 128, 128),
  };

  final key =
      lookup.keys.firstWhereOrNull((regex) => regex.hasMatch(locationName));

  if (key == null) {
    return const Color.fromARGB(255, 255, 255, 255);
  }

  return lookup[key]!;
}
