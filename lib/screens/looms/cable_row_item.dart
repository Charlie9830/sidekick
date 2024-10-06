import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/cable_model.dart';

class CableRowItem extends StatelessWidget {
  final CableModel cable;
  final String labelColor;
  final bool showTopBorder;
  final bool isSelected;
  final bool isDragSelecting;
  final bool hideLength;
  final bool isExtension;

  const CableRowItem({
    super.key,
    required this.cable,
    required this.labelColor,
    this.showTopBorder = false,
    this.isSelected = false,
    this.isDragSelecting = false,
    this.hideLength = false,
    this.isExtension = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          border: Border(
            bottom: const BorderSide(color: Colors.grey),
            top: showTopBorder
                ? const BorderSide(color: Colors.grey)
                : BorderSide.none,
          )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (hideLength == false) ...[
                  SizedBox(
                      width: 100,
                      child: Text('${cable.length.floor().toString()}m')),
                  const VerticalDivider(
                    color: Colors.grey,
                  ),
                ],
                SizedBox(
                    width: 300,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_humanFriendlyType(cable.type)),
                        if (isExtension)
                          SizedBox(
                            height: 24,
                            
                            child: Chip(
                                backgroundColor: Colors.teal.shade700,
                                labelStyle: Theme.of(context).textTheme.bodySmall,
                                padding: const EdgeInsets.only(bottom: 8),
                                label: const Text('Ext')),
                          )
                      ],
                    )),
                const VerticalDivider(
                  color: Colors.grey,
                ),
                SizedBox(width: 300, child: Text(cable.label)),
                const VerticalDivider(
                  color: Colors.grey,
                ),
                SizedBox(width: 300, child: Text(labelColor)),
                const VerticalDivider(
                  color: Colors.grey,
                ),
                SizedBox(width: 300, child: Text(cable.notes)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color? _getBackgroundColor(BuildContext context) {
    if (isSelected) {
      return Theme.of(context).focusColor.withAlpha(60);
    }

    if (isDragSelecting) {
      return Theme.of(context).hoverColor.withAlpha(20);
    }

    return null;
  }
}

String _humanFriendlyType(CableType type) {
  return switch (type) {
    CableType.dmx => 'DMX',
    CableType.socapex => 'Soca',
    CableType.sneak => 'Sneak',
    CableType.wieland6way => '6way',
    CableType.unknown => "Unknown",
  };
}
