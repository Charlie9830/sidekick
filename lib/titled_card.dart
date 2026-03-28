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
        CardTitle(title: title),
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

class CardTitle extends StatelessWidget {
  const CardTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(title).h4,
    );
  }
}
