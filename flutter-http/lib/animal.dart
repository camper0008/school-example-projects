import 'dart:convert';

import 'package:animal_farm/logo.dart';
import 'package:http/http.dart' as http;
import 'package:animal_farm/config.dart';
import 'package:animal_farm/page_scaffold.dart';
import 'package:flutter/material.dart';

sealed class _Response {
  static fromJson(Map<String, dynamic> body) {
    if (body["ok"]) {
      return _SuccessResponse(animal: body["animal"]);
    } else {
      return _ErrorResponse(message: body["message"]);
    }
  }
}

final class _ErrorResponse extends _Response {
  final String message;
  _ErrorResponse({required this.message});
}

final class _SuccessResponse extends _Response {
  final String animal;
  _SuccessResponse({required this.animal});
}

class AnimalPage extends StatefulWidget {
  const AnimalPage({super.key, required this.config, required this.token});

  final String token;
  final Config config;

  @override
  State<StatefulWidget> createState() {
    return _AnimalPageState();
  }
}

class _AnimalPageState extends State<AnimalPage> {
  _AnimalPageState();

  _Response _parseResponse(http.Response response) {
    return _Response.fromJson(jsonDecode(response.body));
  }

  @override
  initState() {
    final body = json.encode({"token": widget.token});
    _animal = http
        .post(Uri.parse("${widget.config.apiUrl}/animal"),
            headers: {"Content-Type": "application/json"}, body: body)
        .then(_parseResponse);
    super.initState();
  }

  List<Widget> _displayedResponse(_Response? data) {
    return switch (data) {
      null => [SizedBox()],
      _ErrorResponse(message: final msg) => [
          Text("An error occured: $msg"),
          SizedBox(height: 16.0)
        ],
      _SuccessResponse(animal: final animal) => [
          Text("You are a $animal!"),
          SizedBox(height: 16.0)
        ],
    };
  }

  late final Future<_Response> _animal;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: FutureBuilder(
        future: _animal,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Logo(),
              SizedBox(height: 16.0),
              ..._displayedResponse(snapshot.data)
            ],
          );
        },
      ),
    );
  }
}
