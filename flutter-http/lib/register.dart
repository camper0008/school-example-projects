import 'package:animal_farm/client.dart' as client;
import 'package:animal_farm/logo.dart';
import 'package:animal_farm/page_scaffold.dart';
import 'package:flutter/material.dart';

sealed class _Status {}

final class _Loading extends _Status {}

final class _Ready extends _Status {}

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  _Status _status = _Ready();
  final username = TextEditingController();
  final password = TextEditingController();

  void _gotoLogin() {
    Navigator.pop(context);
  }

  _register(String username, String password) async {
    setState(() => _status = _Loading());
    final response = await client.Client().register(username, password);
    if (!mounted) return;
    final message = switch (response) {
      client.Success<Null>() => "Account created!",
      client.Error<Null>(message: final message) =>
        "Could not create account: $message",
    };
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    setState(() => _status = _Ready());
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Logo(),
          SizedBox(height: 16.0),
          TextField(
            decoration: InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
            ),
            controller: username,
          ),
          SizedBox(height: 16.0),
          TextField(
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              controller: password),
          SizedBox(height: 16.0),
          _status is _Ready
              ? FilledButton(
                  onPressed: () => _register(username.text, password.text),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Register",
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ),
                )
              : CircularProgressIndicator(),
          SizedBox(height: 16.0),
          OutlinedButton(
            onPressed: () => _gotoLogin(),
            child: Text("I already have an account"),
          ),
        ],
      ),
    );
  }
}
