import 'package:sidekick/classes/named_colors.dart';
import 'package:sidekick/data_selectors/select_cable_specific_location.dart';
import 'package:sidekick/data_selectors/select_title_case_color.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/location_model.dart';

String selectCableSpecificLocationColorLabel(
    CableModel cable, Map<String, LocationModel> locations) {
  final location = selectCableSpecificLocation(cable, locations);

  if (location == null) {
    return '';
  }

  return selectTitleCaseColor(NamedColors.names[location.color] ?? '');
}
