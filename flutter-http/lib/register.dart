import 'package:animal_farm/client.dart' as client;
import 'package:animal_farm/logo.dart';
import 'package:animal_farm/page_scaffold.dart';
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
      Consumer<_RegisterRequest>(
        builder: (context, request, child) {
          final onPressed = request.status is! _Loading
              ? () => request.register(username.text, password.text)
              : null;
          return FilledButton(
            onPressed: onPressed,
            child: child,
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

sealed class _Status {}

final class _Error extends _Status {
  final String message;
  _Error({required this.message});
}

final class _Loading extends _Status {}

final class _Success extends _Status {}

class _RegisterRequest extends ChangeNotifier {
  _RegisterRequest();

  _Status? status;

  void register(String username, String password) async {
    status = _Loading();
    notifyListeners();
    final res = await client.Client().register(username, password);
    status = switch (res) {
      client.Success<Null>() => _Success(),
      client.Error<Null>(message: final message) => _Error(message: message),
    };
    notifyListeners();
  }
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({
    super.key,
  });

  void _gotoLogin(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: ChangeNotifierProvider(
        create: (_) => _RegisterRequest(),
        builder: (context, _) {
          final status = switch (context.watch<_RegisterRequest>().status) {
            null => SizedBox(),
            _Loading() => CircularProgressIndicator(),
            _Error(message: final message) =>
              Text("An error occurred: $message"),
            _Success() => Text("Account created!"),
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
                onPressed: () => _gotoLogin(context),
                child: Text("I already have an account"),
              ),
            ],
          );
        },
      ),
    );
  }
}
