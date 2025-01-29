import 'dart:convert';

import 'package:animal_farm/config.dart';
import 'package:animal_farm/login.dart';
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
      Consumer<_State>(
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

sealed class _Response {
  static fromJson(Map<String, dynamic> body) {
    if (body["ok"]) {
      return _SuccessResponse();
    } else {
      return _ErrorResponse(message: body["message"]);
    }
  }
}

final class _NoneResponse extends _Response {}

final class _ErrorResponse extends _Response {
  final String message;
  _ErrorResponse({required this.message});
}

final class _SuccessResponse extends _Response {}

class _State extends ChangeNotifier {
  Future<_Response> future = Future.value(_NoneResponse());
  final String apiUrl;

  _State({required this.apiUrl});

  _Response _parseResponse(http.Response response) {
    return _Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  void register(String username, String password) {
    final body = json.encode({"username": username, "password": password});
    future = http
        .post(Uri.parse("$apiUrl/register"),
            headers: {"Content-Type": "application/json"}, body: body)
        .then(_parseResponse);
    notifyListeners();
  }
}

List<Widget> _displayedResponse(_Response? data) {
  return switch (data) {
    null || _NoneResponse() => [SizedBox()],
    _ErrorResponse(message: final msg) => [
        Text("An error occured: $msg"),
        SizedBox(height: 16.0)
      ],
    _SuccessResponse() => [Text("Account created!"), SizedBox(height: 16.0)],
  };
}

class RegisterPage extends StatelessWidget {
  final Config config;

  const RegisterPage({super.key, required this.config});

  void _gotoLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(config: config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: ChangeNotifierProvider(
        create: (_) => _State(apiUrl: config.apiUrl),
        builder: (context, _) {
          return FutureBuilder(
            future: Provider.of<_State>(context).future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Logo(),
                  SizedBox(height: 16.0),
                  _Form(),
                  SizedBox(height: 16.0),
                  ..._displayedResponse(snapshot.data),
                  OutlinedButton(
                    onPressed: () => _gotoLogin(context),
                    child: Text("I already have an account"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
