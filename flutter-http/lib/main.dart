import 'package:animal_farm/animal.dart';
import 'package:animal_farm/session.dart';
import 'package:flutter/material.dart';
import 'package:animal_farm/login.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Farm',
      theme: ThemeData(useMaterial3: true),
      home: ChangeNotifierProvider(
        create: (_) => Session(),
        builder: (context, _) {
          final session = context.watch<Session>();
          return switch (session.status) {
            LoggedIn(token: final token) => AnimalPage(token: token),
            LoggedOut() => LoginPage(),
          };
        },
      ),
    );
  }
}
