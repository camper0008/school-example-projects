import 'dart:convert';

import 'package:animal_farm/config.dart';
import 'package:animal_farm/login.dart';
import 'package:animal_farm/logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class _RegisterForm extends StatelessWidget {
  _RegisterForm();

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
      Consumer<RegisterState>(
        builder: (context, value, child) {
          return FilledButton(
            child: child,
            onPressed: () {
              value.register(username.text, password.text);
            },
          );
        },
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Register",
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      )
    ]);
  }
}

sealed class RegisterResult {
  static fromJson(Map<String, dynamic> body) {
    if (body["ok"]) {
      return Success();
    } else {
      return Error(message: body["message"]);
    }
  }
}

final class None extends RegisterResult {}

final class Error extends RegisterResult {
  final String message;
  Error({required this.message});
}

final class Success extends RegisterResult {}

class RegisterState extends ChangeNotifier {
  Future<RegisterResult> future = Future.value(None());
  final String apiUrl;

  RegisterState({required this.apiUrl});

  RegisterResult _parseResponse(http.Response response) {
    return RegisterResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  void register(String username, String password) {
    final body = json.encode({"username": username, "password": password});
    future = http
        .post(Uri.parse("$apiUrl/register"),
            headers: {"Content-Type": "application/json"}, body: body)
        .then(_parseResponse);
  }
}

class RegisterPage extends StatelessWidget {
  final Config config;

  const RegisterPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterState(apiUrl: config.apiUrl),
      child: Scaffold(
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
                  _RegisterForm(),
                  SizedBox(height: 16.0),
                  OutlinedButton(
                    child: Text("I already have an account"),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              LoginPage(config: config),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
