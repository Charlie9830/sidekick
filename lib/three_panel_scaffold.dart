import 'package:flutter/cupertino.dart';

class ThreePanelScaffold extends StatelessWidget {
  final Widget toolbar;
  final Widget sidebar;
  final Widget body;

  const ThreePanelScaffold(
      {super.key,
      required this.toolbar,
      required this.sidebar,
      required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        toolbar,
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [sidebar, Expanded(child: body)],
        ))
      ],
    );
  }
}
