import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:app/ui.dart' as ui;

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
      if (leaderboard.isNotEmpty) Divider(),
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

class Soldier extends StatelessWidget {
  final ui.Soldier soldier;

  const Soldier(this.soldier, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
        "${soldier.name} - ⚔️ ${soldier.damage} - ${"❤️" * soldier.health}");
  }
}

class BattleTriviaPage extends StatefulWidget {
  final String question;
  final List<String> answers;
  final int countdown;
  final WebSocketSink sink;
  const BattleTriviaPage({
    super.key,
    required this.sink,
    required this.question,
    required this.answers,
    required this.countdown,
  });

  @override
  State<BattleTriviaPage> createState() => _BattleTriviaPageState();
}

class _BattleTriviaPageState extends State<BattleTriviaPage> {
  bool answered = false;

  @override
  void initState() {
    super.initState();
    answered = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("${widget.countdown}..."),
      Divider(),
      Text(widget.question),
      ...widget.answers.asMap().entries.map((entry) => FilledButton(
          onPressed: !answered
              ? () {
                  if (answered) return;
                  widget.sink
                      .add(jsonEncode({"tag": "answer", "answer": entry.key}));
                  setState(() => answered = true);
                }
              : null,
          child: Text(entry.value))),
    ]);
  }
}

class BattleIdlePage extends StatelessWidget {
  final ui.Base you;
  final ui.Enemy enemy;
  final int countdown;
  const BattleIdlePage({
    super.key,
    required this.you,
    required this.enemy,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("Question in $countdown..."),
      Divider(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("${enemy.name}:", style: TextStyle(fontSize: 20.0)),
        Text("❤️" * enemy.base.health, style: TextStyle(fontSize: 20.0)),
      ]),
      Column(
          children:
              enemy.base.soldiers.map((soldier) => Soldier(soldier)).toList()),
      Divider(),
      Column(
          children: you.soldiers.map((soldier) => Soldier(soldier)).toList()),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("You:", style: TextStyle(fontSize: 20.0)),
        Text("❤️" * you.health, style: TextStyle(fontSize: 20.0)),
      ]),
    ]);
  }
}

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  State<StatefulWidget> createState() => _PageState();
}

class _PageState extends State<Page> {
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
        final value = ui.UI.fromJson(jsonDecode(snapshot.data));
        switch (value) {
          case ui.Leaderboard(
              leaderboard: final leaderboard,
              you: final you,
              users: final users
            ):
            return LeaderboardPage(
              leaderboard: leaderboard,
              you: you,
              users: users,
            );
          case ui.RegisterName():
            return RegisterPage(sink: channel.sink);
          case ui.Unhandled(body: final body):
            return Center(
              child: Text(
                "unhandled: '$body'",
                style: TextStyle(fontSize: 24.0),
              ),
            );
          case ui.BattleIdle(
              you: final you,
              enemy: final enemy,
              countdown: final countdown,
            ):
            return BattleIdlePage(you: you, enemy: enemy, countdown: countdown);
          case ui.BattleTrivia(
              countdown: final countdown,
              question: final question,
              answers: final answers,
            ):
            return BattleTriviaPage(
              sink: channel.sink,
              question: question,
              answers: answers,
              countdown: countdown,
            );
          case ui.TriviaWaitingOnEnemy(countdown: final countdown):
            return Center(
              child: Text(
                "Waiting on enemy... ($countdown)",
                style: TextStyle(fontSize: 24.0),
              ),
            );
        }
      },
    );
  }
}
