import 'dart:convert';

import 'package:animal_farm/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

sealed class AuthenticationStatus {
  static fromJson(Map<String, dynamic> body) {
    if (body["ok"]) {
      return LoggedIn(token: body["token"]);
    } else {
      return Error(message: body["message"]);
    }
  }
}

final class LoggedOut extends AuthenticationStatus {}

final class Loading extends AuthenticationStatus {}

final class Error extends AuthenticationStatus {
  final String message;
  Error({required this.message});
}

final class LoggedIn extends AuthenticationStatus {
  final String token;
  LoggedIn({required this.token});
}

class Authentication extends ChangeNotifier {
  AuthenticationStatus status = LoggedOut();
  Config config;

  Authentication({required this.config});

  AuthenticationStatus _parseResponse(http.Response response) {
    return AuthenticationStatus.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  void login({required String username, required String password}) async {
    final body = json.encode({"username": username, "password": password});
    status = Loading();
    notifyListeners();
    status = await http
        .post(Uri.parse("${config.apiUrl}/login"),
            headers: {"Content-Type": "application/json"}, body: body)
        .then(_parseResponse);
    notifyListeners();
  }

  void logout() {
    status = LoggedOut();
  }
}
