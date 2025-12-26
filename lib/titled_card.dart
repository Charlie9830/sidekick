import 'package:shadcn_flutter/shadcn_flutter.dart';

class TitledCard extends StatelessWidget {
  final String title;
  final Widget child;

  const TitledCard({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title).h4,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        )
      ],
    );
  }
}
