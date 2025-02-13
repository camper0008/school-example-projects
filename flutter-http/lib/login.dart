import 'package:animal_farm/client.dart' as client;
import 'package:animal_farm/register.dart';
import 'package:animal_farm/logo.dart';
import 'package:animal_farm/page_scaffold.dart';
import 'package:animal_farm/session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

sealed class _Status {}

final class _Loading extends _Status {}

final class _Ready extends _Status {}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  _Status _status = _Ready();
  final username = TextEditingController();
  final password = TextEditingController();

  void _gotoRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()));
  }

  _login(String username, String password) async {
    setState(() => _status = _Loading());
    final response = await client.Client().login(username, password);
    if (!mounted) return;
    switch (response) {
      case client.Success<String>(data: final token):
        final session = context.read<Session>();
        session.login(token);
      case client.Error<String>(message: final message):
        final snackBar =
            SnackBar(content: Text("Could not login to account: $message"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() => _status = _Ready());
    }
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
                  onPressed: () => _login(username.text, password.text),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Login",
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ),
                )
              : CircularProgressIndicator(),
          SizedBox(height: 16.0),
          OutlinedButton(
            onPressed: () => _gotoRegister(),
            child: Text("I don't have an account"),
          ),
        ],
      ),
    );
  }
}
