import 'package:flutter/material.dart';

String titleCaseColor(String colorName) {
  if (colorName.isEmpty) {
    return '';
  }

  if (colorName.contains('/') == false) {
    return colorName.replaceFirst(
        colorName.characters.first, colorName.characters.first.toUpperCase());
  }

  return colorName.split('/').map((color) => titleCaseColor(color)).join('/');
}
