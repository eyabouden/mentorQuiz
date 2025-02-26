import 'package:flutter/material.dart';
import '/models/quiz.dart';

class QuizTile extends StatelessWidget {
  final Quiz quiz;

  QuizTile({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(quiz.title),
      subtitle: Text('Created at: ${quiz.createdAt}'),
      onTap: () {
        // Navigate to the quiz details or joining page
      },
    );
  }
}
