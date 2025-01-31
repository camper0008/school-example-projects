import 'package:animal_farm/client.dart' as client;
import 'package:flutter/material.dart';

sealed class Status {}

final class LoggedOut extends Status {}

final class Loading extends Status {}

final class Error extends Status {
  final String message;
  Error({required this.message});
}

final class LoggedIn extends Status {
  final String token;
  LoggedIn({required this.token});
}

class Session extends ChangeNotifier {
  Status status = LoggedOut();

  Session();

  void login({required String username, required String password}) async {
    status = Loading();
    notifyListeners();
    final res = await client.Client().login(username, password);
    status = switch (res) {
      client.Success<String>(data: final token) => LoggedIn(token: token),
      client.Error<String>(message: final message) => Error(message: message),
    };
    notifyListeners();
  }

  void logout() {
    status = LoggedOut();
    notifyListeners();
  }
}
