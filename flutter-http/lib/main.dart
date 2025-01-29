import 'package:animal_farm/config.dart';
import 'package:flutter/material.dart';
import 'package:animal_farm/login.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Config(apiUrl: "http://localhost:8080");

    return MaterialApp(
      title: 'Animal Farm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(config: config),
    );
  }
}
