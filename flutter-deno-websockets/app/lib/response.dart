import 'dart:convert';

sealed class Response {
  static Response fromJson(Map<String, dynamic> obj) {
    switch (obj["tag"]) {
      case "register_name":
        return RegisterName();
      case "battle":
        return Battle.fromJson(obj["battle"]);
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
        return BattleTrivia.fromJson(obj);
      case "trivia_waiting_on_enemy":
        return TriviaWaitingOnEnemy.fromJson(obj);
      case "idle":
        return BattleIdle.fromJson(obj);
      default:
        return Unhandled(jsonEncode(obj));
    }
  }
}

class Soldier {
  final String name;
  final int health;
  final int damage;
  Soldier.fromJson(Map<String, dynamic> obj)
      : name = obj["name"],
        damage = obj["damage"],
        health = obj["health"];
}

class Base {
  final int health;
  final List<Soldier> soldiers;

  Base.fromJson(Map<String, dynamic> obj)
      : health = obj["health"],
        soldiers = (obj["soldiers"] as List<dynamic>)
            .map((soldier) => Soldier.fromJson(soldier))
            .toList();
}

class Enemy {
  final String name;
  final Base base;

  Enemy.fromJson(Map<String, dynamic> obj)
      : name = obj["name"],
        base = Base.fromJson(obj["base"]);
}

class BattleIdle extends Battle {
  final int countdown;
  final Base you;
  final Enemy enemy;

  BattleIdle.fromJson(Map<String, dynamic> obj)
      : countdown = obj["countdown"],
        you = Base.fromJson(obj["you"]),
        enemy = Enemy.fromJson(obj["enemy"]);
}

class BattleTrivia extends Battle {
  final int countdown;
  final String question;
  final List<String> answers;

  BattleTrivia.fromJson(Map<String, dynamic> obj)
      : countdown = obj["countdown"],
        question = obj["question"],
        answers =
            (obj["answers"] as List<dynamic>).map((v) => v as String).toList();
}

class TriviaWaitingOnEnemy extends Battle {
  final int countdown;

  TriviaWaitingOnEnemy.fromJson(Map<String, dynamic> obj)
      : countdown = obj["countdown"];
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
