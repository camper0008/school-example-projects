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

class TimeoutReached extends QuestionResult {}

Future<QuestionResult> showQuestionDialog(
    {required BuildContext context,
    required String question,
    required (Answer, Answer, Answer, Answer) answers}) async {
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
  final (Answer, Answer, Answer, Answer) answers;

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

  late final Timer _lerpTimer;

  @override
  void initState() {
    gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        rotation = Vec2d(x: rotation.x + event.y, y: rotation.y + event.x);
      },
      onError: (error) {},
      cancelOnError: true,
    );
    _lerpTimer = Timer.periodic(Duration(milliseconds: 33), (_) => _lerpPtr());
    super.initState();
  }

  double _lerp(double pos, double tgt, double alpha) {
    return (tgt - pos) * alpha + pos;
  }

  void _lerpPtr() {
    setState(() {
      ptr = Vec2d(
          x: _lerp(ptr.x, rotation.x, 0.1), y: _lerp(ptr.y, rotation.y, 0.1));
    });
  }

  @override
  void dispose() {
    _lerpTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = 32.0;
    final (topLeft, topRight, bottomLeft, bottomRight) = widget.answers;
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          bool correct;
          if (ptr.x <= 0 && ptr.y <= 0) {
            correct = topLeft.correct;
          } else if (ptr.x <= 0 && ptr.y > 0) {
            correct = bottomLeft.correct;
          } else if (ptr.x > 0 && ptr.y <= 0) {
            correct = topRight.correct;
          } else if (ptr.x > 0 && ptr.y > 0) {
            correct = bottomRight.correct;
          } else {
            throw Exception("unreachable");
          }
          Navigator.of(context).pop(AnsweredQuestion(correct));
        },
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  widget.question,
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        spacing: spacing,
                        children: [
                          Expanded(
                            child: Column(
                              spacing: spacing,
                              children: [
                                Expanded(
                                  child: _Answer(
                                    text: topLeft.text,
                                    highlighted: ptr.x <= 0 && ptr.y <= 0,
                                  ),
                                ),
                                Expanded(
                                  child: _Answer(
                                    text: bottomLeft.text,
                                    highlighted: ptr.x <= 0 && ptr.y > 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              spacing: spacing,
                              children: [
                                Expanded(
                                  child: _Answer(
                                    text: topRight.text,
                                    highlighted: ptr.x > 0 && ptr.y <= 0,
                                  ),
                                ),
                                Expanded(
                                  child: _Answer(
                                    text: bottomRight.text,
                                    highlighted: ptr.x > 0 && ptr.y > 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Pointer(x: ptr.x, y: ptr.y)
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Tap to lock answer in",
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
