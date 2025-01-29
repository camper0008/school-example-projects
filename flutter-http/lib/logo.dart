import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        'Animal Farm',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(
        'Jorjorwell © 1984',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ]);
  }
}
