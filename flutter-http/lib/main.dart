import 'package:animal_farm/animal.dart';
import 'package:animal_farm/config.dart';
import 'package:animal_farm/authentication.dart';
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
    final config = Config(apiUrl: "http://localhost:8080");

    return MaterialApp(
      title: 'Animal Farm',
      theme: ThemeData(useMaterial3: true),
      home: ChangeNotifierProvider(
        create: (_) => Authentication(config: config),
        builder: (context, _) {
          final session = context.watch<Authentication>();
          switch (session.status) {
            case LoggedIn(token: final token):
              return AnimalPage(config: config, token: token);
            default:
              return LoginPage(config: config);
          }
        },
      ),
    );
  }
}
