import 'package:animal_farm/config.dart';
import 'package:animal_farm/register.dart';
import 'package:animal_farm/logo.dart';
import 'package:animal_farm/page_scaffold.dart';
import 'package:animal_farm/authentication.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Form extends StatelessWidget {
  _Form();

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
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
      Consumer<Authentication>(
        builder: (context, auth, child) {
          if (auth.status case Loading()) {
            return FilledButton(
              onPressed: null,
              child: child,
            );
          } else {
            return FilledButton(
              onPressed: () {
                auth.login(username: username.text, password: password.text);
              },
              child: child,
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Login",
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      )
    ]);
  }
}

class LoginPage extends StatelessWidget {
  final Config config;

  const LoginPage({super.key, required this.config});

  void _gotoRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => RegisterPage(config: config),
      ),
    );
  }

  Widget _renderStatus(AuthenticationStatus status) {
    switch (status) {
      case LoggedOut():
        return SizedBox();
      case Loading():
        return CircularProgressIndicator();
      case Error(message: final message):
        return Text("An error occurred: $message");
      case LoggedIn():
        return Text("Logged in!");
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
          _Form(),
          SizedBox(height: 16.0),
          Consumer<Authentication>(builder: (context, auth, child) {
            return _renderStatus(auth.status);
          }),
          SizedBox(height: 16.0),
          OutlinedButton(
            onPressed: () => _gotoRegister(context),
            child: Text("I don't have an account"),
          ),
        ],
      ),
    );
  }
}
