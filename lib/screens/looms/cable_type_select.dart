import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/cable_model.dart';

class CableTypeSelect extends StatelessWidget {
  final CableType value;
  final void Function(CableType newValue) onChanged;
  final Set<CableType>? allowedTypes;

  const CableTypeSelect(
      {super.key,
      required this.value,
      required this.onChanged,
      this.allowedTypes});

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
                    child: Text(_getHumanFriendlyCableTypeName(type))),
              )
              .toList(),
        ),
      ),
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
    };
  }
}
