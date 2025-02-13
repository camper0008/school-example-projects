import 'package:flutter/material.dart';

sealed class Status {}

final class LoggedOut extends Status {}

final class LoggedIn extends Status {
  final String token;
  LoggedIn({required this.token});
}

class Session extends ChangeNotifier {
  Status status = LoggedOut();

  Session();

  void login(String token) {
    status = LoggedIn(token: token);
    notifyListeners();
  }

  void logout() {
    status = LoggedOut();
    notifyListeners();
  }
}
