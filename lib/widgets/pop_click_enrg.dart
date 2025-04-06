import 'package:flutter/material.dart';
import 'package:mentor_quiz/quizcodeandqr.dart';

class QuizPopup extends StatefulWidget {
  final String quizName;
  final String quizId; // Ajoutez cette ligne pour passer l'ID du quiz

  const QuizPopup({
    Key? key,
    required this.quizName,
    required this.quizId, // Ajoutez cette ligne
  }) : super(key: key);

  @override
  _QuizPopupState createState() => _QuizPopupState();
}

class _QuizPopupState extends State<QuizPopup> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quiz: ${widget.quizName}',
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Fermez le popup
                Navigator.of(context).pop();
                // Naviguez vers QuizAccessPage
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuizAccessPage(
                      quizName: widget.quizName,
                      quizId: widget.quizId,
                    ),
                  ),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }}