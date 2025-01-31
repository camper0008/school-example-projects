import 'package:animal_farm/client.dart' as client;
import 'package:animal_farm/session.dart' as session;
import 'package:animal_farm/logo.dart';
import 'package:animal_farm/page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

sealed class _Status {}

final class _Error extends _Status {
  final String message;
  _Error({required this.message});
}

final class _Success extends _Status {
  final String animal;
  _Success({required this.animal});
}

class AnimalPage extends StatefulWidget {
  const AnimalPage({super.key, required this.token});

  final String token;

  @override
  State<StatefulWidget> createState() {
    return _AnimalPageState();
  }
}

class _AnimalPageState extends State<AnimalPage> {
  _AnimalPageState();

  @override
  initState() {
    _animal = client.Client()
        .animal(widget.token)
        .then((response) => switch (response) {
              client.Success<String>(data: final animal) =>
                _Success(animal: animal),
              client.Error<String>(message: final message) =>
                _Error(message: message),
            });
    super.initState();
  }

  late final Future<_Status> _animal;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: FutureBuilder(
        future: _animal,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Logo(),
              SizedBox(height: 16.0),
              switch (snapshot.data) {
                null => throw Exception("unreachable"),
                _Error(message: final message) =>
                  Text("An error occurred: $message"),
                _Success(animal: final animal) => Text("You are a $animal!"),
              },
              SizedBox(height: 32.0),
              FilledButton(
                onPressed: () {
                  context.read<session.Session>().logout();
                },
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Logout",
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
