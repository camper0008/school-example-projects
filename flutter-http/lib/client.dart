import 'dart:convert';

import 'package:http/http.dart' as http;

class Client {
  final _apiUrl = "http://localhost:8080";

  Future<http.Response> _post(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final encoded = json.encode(body);
    return await http.post(
      Uri.parse("$_apiUrl/$endpoint"),
      body: encoded,
      headers: {"Content-Type": "application/json"},
    );
  }

  Future<Response<Null>> register(
    String username,
    String password,
  ) async {
    final res = await _post(
      endpoint: "register",
      body: {"username": username, "password": password},
    ).then((res) => json.decode(res.body));

    if (res["ok"]) {
      return Success(data: null);
    } else {
      return Error(message: res["message"]);
    }
  }

  Future<Response<String>> login(
    String username,
    String password,
  ) async {
    final res = await _post(
      endpoint: "login",
      body: {"username": username, "password": password},
    ).then((res) => json.decode(res.body));

    if (res["ok"]) {
      return Success(data: res["token"]);
    } else {
      return Error(message: res["message"]);
    }
  }

  Future<Response<String>> animal(
    String token,
  ) async {
    final res = await _post(
      endpoint: "animal",
      body: {"token": token},
    ).then((res) => json.decode(res.body));

    if (res["ok"]) {
      return Success(data: res["animal"]);
    } else {
      return Error(message: res["message"]);
    }
  }
}

sealed class Response<Data> {}

class Success<Data> extends Response<Data> {
  Data data;
  Success({required this.data});
}

class Error<Data> extends Response<Data> {
  String message;
  Error({required this.message});
}
