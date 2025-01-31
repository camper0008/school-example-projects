import 'package:animal_farm/register.dart';
import 'package:animal_farm/logo.dart';
import 'package:animal_farm/page_scaffold.dart';
import 'package:animal_farm/session.dart' as session;
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
      Consumer<session.Session>(
        builder: (context, auth, child) {
          final onPressed = auth.status is! session.Loading
              ? () =>
                  auth.login(username: username.text, password: password.text)
              : null;
          return FilledButton(
            onPressed: onPressed,
            child: child,
          );
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
  const LoginPage({
    super.key,
  });

  void _gotoRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => RegisterPage(),
      ),
    );
  }

  Widget _renderStatus(session.Status status) {
    switch (status) {
      case session.LoggedOut():
        return SizedBox();
      case session.Loading():
        return CircularProgressIndicator();
      case session.Error(message: final message):
        return Text("An error occurred: $message");
      case session.LoggedIn():
        return throw Exception("unreachable");
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
          Consumer<session.Session>(builder: (context, auth, child) {
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
