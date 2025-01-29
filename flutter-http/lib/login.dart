import 'package:animal_farm/config.dart';
import 'package:animal_farm/logo.dart';
import 'package:animal_farm/register.dart';
import 'package:flutter/material.dart';

class _LoginForm extends StatelessWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        decoration: InputDecoration(
          labelText: "Username",
          border: OutlineInputBorder(),
        ),
      ),
      SizedBox(height: 16.0),
      TextField(
        decoration: InputDecoration(
          labelText: "Password",
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
      SizedBox(height: 16.0),
      FilledButton(
          child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Login", style: TextStyle(fontSize: 20.0))),
          onPressed: () {}),
    ]);
  }
}

class LoginPage extends StatelessWidget {
  final Config config;
  const LoginPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(Size(1000.0, double.infinity)),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Logo(),
                SizedBox(height: 16.0),
                _LoginForm(),
                SizedBox(height: 16.0),
                OutlinedButton(
                  child: Text("I don't have an account"),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            RegisterPage(config: config),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
