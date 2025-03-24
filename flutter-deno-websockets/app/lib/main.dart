import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:app/response.dart' as response;

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(body: Page()),
    );
  }
}

class LeaderboardPage extends StatelessWidget {
  final String you;
  final Map<String, int> leaderboard;
  final List<String> users;

  const LeaderboardPage({
    super.key,
    required this.you,
    required this.users,
    required this.leaderboard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(
        "Leaderboard",
        style: TextStyle(fontSize: 20.0),
      ),
      Divider(),
      ...leaderboard.entries
          .map((entry) => Text("${entry.key}: ${entry.value}")),
      Divider(),
      Text(
        you,
        style: TextStyle(fontSize: 20.0),
      ),
      Text(
        "Players: ${users.join(", ")}",
        style: TextStyle(fontSize: 20.0),
      ),
    ]);
  }
}

class RegisterPage extends StatefulWidget {
  final WebSocketSink sink;

  const RegisterPage({super.key, required this.sink});

  @override
  State<StatefulWidget> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8.0,
        children: [
          Text(
            "What is your name?",
            style: TextStyle(fontSize: 20.0),
          ),
          ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300),
              child: TextField(controller: controller)),
          FilledButton(
              onPressed: () {
                widget.sink.add(jsonEncode(
                    {"tag": "register", "name": controller.value.text}));
              },
              child: Text("Submit"))
        ],
      ),
    );
  }
}

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  State<StatefulWidget> createState() => PageState();
}

class PageState extends State<Page> {
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:8000'),
  );

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: channel.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("error occurred: '${snapshot.error}'",
                  style: TextStyle(fontSize: 24.0)));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final value = response.Response.fromJson(jsonDecode(snapshot.data));
        switch (value) {
          case response.Leaderboard(
              leaderboard: final leaderboard,
              you: final you,
              users: final users
            ):
            return LeaderboardPage(
                leaderboard: leaderboard, you: you, users: users);
          case response.RegisterName():
            return RegisterPage(sink: channel.sink);
          case response.Unhandled(body: final body):
            return Center(
                child: Text("unhandled: '$body'",
                    style: TextStyle(fontSize: 24.0)));
        }
      },
    );
  }
}
