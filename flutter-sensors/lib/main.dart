import 'package:flutter/material.dart';
import 'package:flutter_sensors/question_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String resultText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              child: Text("Get a question"),
              onPressed: () async {
                final result = await showQuestionDialog(
                  context: context,
                  question: "What is the airspeed of an unladen swallow?",
                  answers: Answers(
                    Answer("top left (correct)", correct: true),
                    Answer("top right", correct: false),
                    Answer("bottom left (correct)", correct: true),
                    Answer("bottom left", correct: false),
                  ),
                );
                switch (result) {
                  case AnsweredQuestion(correct: final correct):
                    setState(() {
                      if (correct) {
                        resultText = "ding ding ding";
                      } else {
                        resultText = "WRONG!";
                      }
                    });
                  case TimeoutReached():
                    setState(() {
                      resultText = "looks like you weren't quick enough...";
                    });
                }
              },
            ),
            Text(resultText),
          ],
        ),
      ),
    );
  }
}
