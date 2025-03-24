import 'dart:convert';

sealed class Response {
  static Response fromJson(Map<String, dynamic> obj) {
    switch (obj["tag"]) {
      case "register_name":
        return RegisterName();
      case "battle":
        Battle.fromJson(obj);
      case "leaderboard":
        return Leaderboard.fromJson(obj);
      default:
        return Unhandled(jsonEncode(obj));
    }
  }
}

sealed class Battle implements Response {
  static Response fromJson(Map<String, dynamic> obj) {
    switch (obj["tag"]) {
      case "trivia":
        return Trivia.fromJson(obj["battle"]);
      case "idle":
      default:
        return Unhandled(jsonEncode(obj));
    }
  }
}

// soldier = { name: string, damage: int, health: int }

// {
//   tag: "idle",
//   you: {"health": int, soldiers: Soldier[]},
//   enemy: { name: string, base: { health: int, soldiers: Soldier[] }
//   countdown: int
// }
class Idle extends Battle {
  final int countdown;
  final String question;
  final List<String> answers;

  Idle.fromJson(Map<String, dynamic> obj)
      : countdown = obj["countdown"],
        question = obj["trivia"]["question"],
        answers = (obj["trivia"]["answers"] as List<dynamic>)
            .map((v) => v as String)
            .toList();
}

class Trivia extends Battle {
  final int countdown;
  final String question;
  final List<String> answers;

  Trivia.fromJson(Map<String, dynamic> obj)
      : countdown = obj["countdown"],
        question = obj["trivia"]["question"],
        answers = (obj["trivia"]["answers"] as List<dynamic>)
            .map((v) => v as String)
            .toList();
}

class Leaderboard implements Response {
  final String you;
  final List<String> users;
  final Map<String, int> leaderboard;
  Leaderboard.fromJson(Map<String, dynamic> obj)
      : you = obj["you"],
        users =
            (obj["users"] as List<dynamic>).map((v) => v as String).toList(),
        leaderboard = (obj["leaderboard"] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value as int));
}

class Unhandled implements Response {
  final String body;
  const Unhandled(this.body);
}

class RegisterName implements Response {}
