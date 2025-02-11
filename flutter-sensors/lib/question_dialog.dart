import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class Answer {
  final String text;
  final bool correct;

  const Answer(this.text, {required this.correct});
}

sealed class QuestionResult {}

class AnsweredQuestion extends QuestionResult {
  bool correct;

  AnsweredQuestion(this.correct);
}

class Answers {
  final Answer topLeft;
  final Answer topRight;
  final Answer bottomLeft;
  final Answer bottomRight;

  Answers(this.topLeft, this.topRight, this.bottomLeft, this.bottomRight);
}

class TimeoutReached extends QuestionResult {}

Future<QuestionResult> showQuestionDialog(
    {required BuildContext context,
    required String question,
    required Answers answers}) async {
  final value = await Navigator.push<QuestionResult>(
    context,
    MaterialPageRoute(
      builder: (context) => _QuestionDialog(
        question: question,
        answers: answers,
      ),
    ),
  );
  if (value is! QuestionResult) {
    return TimeoutReached();
  }
  return value;
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog({required this.question, required this.answers});

  final String question;
  final Answers answers;

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _Pointer extends StatelessWidget {
  final double x;
  final double y;
  const _Pointer({required this.x, required this.y});

  double _size(double value, double max) {
    return clampDouble(value, -0.95, 0.95) * max * 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return LayoutBuilder(
      builder: (_, constraints) => Center(
        child: Container(
          transform: Matrix4.translationValues(
            _size(x, constraints.maxWidth),
            _size(y, constraints.maxHeight),
            0,
          ),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.onPrimary, width: 2.0),
          ),
        ),
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  final String text;
  final bool highlighted;
  const _Answer({required this.text, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: highlighted ? colorScheme.onPrimary : colorScheme.primary,
        borderRadius: BorderRadius.all(
          Radius.circular(8.0),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: highlighted ? colorScheme.primary : colorScheme.onPrimary,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class Vec2d {
  final double x;
  final double y;

  Vec2d({required this.x, required this.y});
  Vec2d.zero()
      : x = 0,
        y = 0;
}

class _QuestionDialogState extends State<_QuestionDialog> {
  Vec2d ptr = Vec2d.zero();
  Vec2d rotation = Vec2d.zero();
  int secondsLeftToAnswer = 90;

  late final Timer _answerTimer;
  late final Timer _lerpTimer;
  late final StreamSubscription _gyroscopeSubscription;

  @override
  void initState() {
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        rotation = Vec2d(x: rotation.x + event.y, y: rotation.y + event.x);
      },
      onError: (error) {},
      cancelOnError: true,
    );
    _lerpTimer = Timer.periodic(Duration(milliseconds: 33), (_) => _lerpPtr());
    _answerTimer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        setState(() {
          secondsLeftToAnswer -= 1;
        });
        if (secondsLeftToAnswer == 0) {
          _timeoutReached();
        }
      },
    );
    super.initState();
  }

  double _lerpDouble(double pos, double tgt, double alpha) {
    return (tgt - pos) * alpha + pos;
  }

  void _lerpPtr() {
    setState(() {
      ptr = Vec2d(
        x: _lerpDouble(ptr.x, rotation.x, 0.1),
        y: _lerpDouble(ptr.y, rotation.y, 0.1),
      );
    });
  }

  @override
  void dispose() {
    _lerpTimer.cancel();
    _answerTimer.cancel();
    _gyroscopeSubscription.cancel();
    super.dispose();
  }

  bool _isAnswerCorrect() {
    bool correct;
    if (ptr.x <= 0 && ptr.y <= 0) {
      correct = widget.answers.topLeft.correct;
    } else if (ptr.x <= 0 && ptr.y > 0) {
      correct = widget.answers.bottomLeft.correct;
    } else if (ptr.x > 0 && ptr.y <= 0) {
      correct = widget.answers.topRight.correct;
    } else if (ptr.x > 0 && ptr.y > 0) {
      correct = widget.answers.bottomRight.correct;
    } else {
      throw Exception("unreachable");
    }
    return correct;
  }

  void _timeoutReached() {
    final result = TimeoutReached();
    return Navigator.of(context).pop(result);
  }

  void _lockAnswerIn() {
    final result = AnsweredQuestion(_isAnswerCorrect());
    return Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _lockAnswerIn(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "${widget.question} ($secondsLeftToAnswer)",
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
              _AnswersScreen(answers: widget.answers, ptr: ptr),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Tap to lock answer in",
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswersScreen extends StatelessWidget {
  const _AnswersScreen({
    required this.answers,
    required this.ptr,
  });

  final double spacing = 32;
  final Answers answers;
  final Vec2d ptr;

  Widget _answerColumn({
    required Answer top,
    required Answer bottom,
    required bool highlighted,
  }) {
    return Expanded(
      child: Column(
        spacing: spacing,
        children: [
          Expanded(
            child: _Answer(
              text: top.text,
              highlighted: highlighted && ptr.y <= 0,
            ),
          ),
          Expanded(
            child: _Answer(
              text: bottom.text,
              highlighted: highlighted && ptr.y > 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                spacing: spacing,
                children: [
                  _answerColumn(
                    top: answers.topLeft,
                    bottom: answers.bottomLeft,
                    highlighted: ptr.x <= 0,
                  ),
                  _answerColumn(
                    top: answers.topRight,
                    bottom: answers.topRight,
                    highlighted: ptr.x > 0,
                  ),
                ],
              ),
            ),
          ),
          _Pointer(x: ptr.x, y: ptr.y)
        ],
      ),
    );
  }
}
