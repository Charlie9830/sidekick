import 'package:flutter/cupertino.dart';

class ToolbarBodyScaffold extends StatelessWidget {
  final Widget toolbar;
  final Widget body;

  const ToolbarBodyScaffold(
      {super.key, required this.toolbar, required this.body});

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
          children: [Expanded(child: body)],
        ))
      ],
    );
  }
}
