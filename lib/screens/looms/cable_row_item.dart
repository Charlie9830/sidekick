import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';

class CableRowItem extends StatelessWidget {
  final CableModel cable;
  final String labelColor;
  final bool showTopBorder;
  final bool isSelected;
  final bool isDragSelecting;
  final bool hideLength;
  final bool isExtension;
  final List<int> sneakUniverses;
  final int dmxUniverse;
  final String label;

  const CableRowItem({
    super.key,
    required this.cable,
    required this.labelColor,
    this.showTopBorder = false,
    this.isSelected = false,
    this.isDragSelecting = false,
    this.hideLength = false,
    this.isExtension = false,
    this.sneakUniverses = const [],
    this.dmxUniverse = 0,
    this.label = '',
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
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Length
                if (hideLength == false) ...[
                  SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${cable.length.floor().toString()}m'),
                          if (cable.length == 0)
                            const Tooltip(
                              waitDuration: Duration(milliseconds: 500),
                              message: 'Invalid Length',
                              child:
                                  Icon(Icons.error, color: Colors.orangeAccent),
                            )
                        ],
                      )),
                  const VerticalDivider(
                    color: Colors.grey,
                  ),
                ],

                // Cable Type
                SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            switch (cable.type) {
                              CableType.socapex => const Icon(
                                  Icons.electric_bolt,
                                  size: 16,
                                  color: Colors.grey),
                              CableType.wieland6way => const Icon(Icons.power,
                                  size: 16, color: Colors.grey),
                              CableType.sneak => const Icon(
                                  Icons.settings_ethernet,
                                  size: 16,
                                  color: Colors.grey),
                              CableType.dmx => const Icon(
                                  Icons.settings_input_svideo,
                                  size: 16,
                                  color: Colors.grey),
                              CableType.unknown => const SizedBox(),
                            },
                            const SizedBox(width: 8),
                            Text(_humanFriendlyType(cable.type)),
                          ],
                        ),
                        switch ((isExtension, cable.isDropper)) {
                          (_, true) => SizedBox(
                              height: 24,
                              child: CableFlag(
                                  text: 'Drop', color: Colors.teal.shade900)),
                          (true, false) => const SizedBox(
                              height: 24, child: CableFlag(text: 'EXT')),
                          _ => const SizedBox(),
                        },
                      ],
                    )),
                const VerticalDivider(
                  color: Colors.grey,
                ),

                // Label
                SizedBox(
                    width: 300,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(label),
                        if (sneakUniverses.isNotEmpty)
                          Text(
                              '  -  ${sneakUniverses.map((universe) => 'U$universe').join(',')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.grey)),
                        if (dmxUniverse != 0)
                          Text('  -  U$dmxUniverse',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.grey)),
                        const Spacer(),
                        if (cable.isSpare)
                          const CableFlag(
                            text: 'Spare',
                            color: Colors.pink,
                          )
                      ],
                    )),
                const VerticalDivider(
                  color: Colors.grey,
                ),
                SizedBox(width: 300, child: Text(labelColor)),
                const VerticalDivider(
                  color: Colors.grey,
                ),
                Expanded(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cable.notes),
                    if (cable.loomId.isEmpty)
                      const Tooltip(
                          message: 'Unloomed Cable',
                          child: Icon(
                            Icons.error,
                            color: Colors.orangeAccent,
                          ))
                  ],
                )),
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
