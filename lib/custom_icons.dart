import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

abstract class CustomIcon extends StatelessWidget {
  final double size;
  const CustomIcon({super.key, this.size = 24});
}

class PlaceItemIcon extends CustomIcon {
  const PlaceItemIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/icons/place_item.svg',
        height: size, width: size);
  }
}
