import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/cable_model.dart';

class CableTypeSelect extends StatelessWidget {
  final CableType value;
  final void Function(CableType newValue) onChanged;
  final Set<CableType>? allowedTypes;

  const CableTypeSelect({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowedTypes,
  });

  @override
  Widget build(BuildContext context) {
    final typeOptions = allowedTypes ?? CableType.values.toSet();

    return Select<CableType>(
      itemBuilder: (context, item) =>
          Text(_getHumanFriendlyCableTypeName(item)),
      value: value,
      onChanged: (value) => value == null ? null : onChanged(value),
      popup: SelectPopup(
        items: SelectItemList(
          children: typeOptions
              .map(
                (type) => SelectItemButton(
                  value: type,
                  child: Text(_getHumanFriendlyCableTypeName(type)),
                ),
              )
              .toList(),
        ),
      ).call,
    );
  }

  String _getHumanFriendlyCableTypeName(CableType type) {
    return switch (type) {
      CableType.unknown => 'Unknown',
      CableType.socapex => 'Socapex',
      CableType.wieland6way => 'Wieland 6way',
      CableType.sneak => 'Sneak Snake',
      CableType.dmx => 'DMX',
      CableType.hoist => 'Motor',
      CableType.hoistMulti => 'Motor Multi',
      CableType.au10a => '10A Extension',
      CableType.true1 => 'True1 Extension',
      CableType.socapexToAu10ALampHeader => 'Socapex AU10A Lamp Header',
      CableType.socapexToTrue1LampHeader => 'Socapex True1 Lamp Header',
      CableType.wieland6WayLampHeader => 'Wieland AU10A Lamp Header',
      CableType.sneakLampHeader => 'Sneak Snake Lamp Header',
      CableType.hoistMultiLampHeader => 'Motor Multi Lamp Header',
      CableType.hoistMultiRackHeader => 'Motor Multi Rack Header',
      CableType.socapexTo6wayAdaptor => 'Socapex to Wieland Adapter',
      CableType.sneakRackHeader => 'Sneak Snake Rack Header',
      CableType.nac3Joiner => 'Powercon Joiner',
      CableType.nac3 => 'Powercon',
      CableType.wilco32a => '32A Wilco',
      CableType.consoleLoom => 'Console Loom',
      CableType.etherconJoiner => 'Ethercon Joiner',
      CableType.ethercon => 'Ethercon',
      CableType.wieland6WayRackHeader => 'Wieland Rack Header',
    };
  }
}
