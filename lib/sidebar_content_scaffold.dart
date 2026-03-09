import 'package:flutter/cupertino.dart';

class SidebarContentScaffold extends StatelessWidget {
  final Widget sidebar;
  final Widget body;

  const SidebarContentScaffold(
      {super.key, required this.sidebar, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
