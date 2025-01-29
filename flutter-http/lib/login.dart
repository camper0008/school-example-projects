import 'dart:convert';

import 'package:animal_farm/config.dart';
import 'package:animal_farm/register.dart';
import 'package:animal_farm/logo.dart';
import 'package:animal_farm/page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

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
      Consumer<_LoginRequest>(
        builder: (context, value, child) {
          return FilledButton(
            child: child,
            onPressed: () {
              value.login(username.text, password.text);
            },
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

sealed class _Response {
  static fromJson(Map<String, dynamic> body) {
    if (body["ok"]) {
      return _Success(token: body["token"]);
    } else {
      return _Error(message: body["message"]);
    }
  }
}

final class _Unitialized extends _Response {}

final class _Loading extends _Response {}

final class _Error extends _Response {
  final String message;
  _Error({required this.message});
}

final class _Success extends _Response {
  final String token;
  _Success({required this.token});
}

class _LoginRequest extends ChangeNotifier {
  _Response response = _Unitialized();
  final String apiUrl;

  _LoginRequest({required this.apiUrl});

  _Response _parseResponse(http.Response response) {
    return _Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  void login(String username, String password) async {
    final body = json.encode({"username": username, "password": password});
    response = _Loading();
    notifyListeners();
    response = await http
        .post(Uri.parse("$apiUrl/login"),
            headers: {"Content-Type": "application/json"}, body: body)
        .then(_parseResponse);
    notifyListeners();
  }
}

class LoginPage extends StatelessWidget {
  final Config config;

  const LoginPage({super.key, required this.config});

  void _gotoRegister(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => RegisterPage(config: config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: ChangeNotifierProvider(
        create: (_) => _LoginRequest(apiUrl: config.apiUrl),
        builder: (context, _) {
          final status = switch (Provider.of<_LoginRequest>(context).response) {
            _Unitialized() => SizedBox(),
            _Loading() => CircularProgressIndicator(),
            _Error(message: final message) =>
              Text("An error occurred: $message"),
            _Success() => Text("Logged in!"),
          };
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Logo(),
              SizedBox(height: 16.0),
              _Form(),
              SizedBox(height: 16.0),
              status,
              SizedBox(height: 16.0),
              OutlinedButton(
                onPressed: () => _gotoRegister(context),
                child: Text("I don't have an account"),
              ),
            ],
          );
        },
      ),
    );
  }
}
