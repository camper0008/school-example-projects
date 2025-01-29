import 'package:animal_farm/config.dart';
import 'package:animal_farm/page_scaffold.dart';
import 'package:flutter/material.dart';

class AnimalPage extends StatelessWidget {
  const AnimalPage({super.key, required this.config, required this.token});

  final String token;
  final Config config;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: Text(token),
    );
  }
}
