import 'dart:async'; // Make sure this import is included
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/quiz.dart';
import 'package:mentor_quiz/models/question.dart';
import 'package:mentor_quiz/models/quizsession.dart';
import 'package:mentor_quiz/models/reponse.dart'; // Ensure the correct import is used for Response (not Answer)
import 'package:mentor_quiz/screens/admin/ResultPage.dart'; // Correct import for ResultPage

class QuizPresentationPage extends StatefulWidget {
  final String quizId;
  final String sessionId;

  const QuizPresentationPage({
    Key? key,
    required this.quizId,
    required this.sessionId,
  }) : super(key: key);

  @override
  _QuizPresentationPageState createState() => _QuizPresentationPageState();
}

class _QuizPresentationPageState extends State<QuizPresentationPage> {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  bool isLoading = true;
  QuizSession? session;
  Map<String, Map<String, int>> participantScores = {};
  late Stream<QuerySnapshot> responsesStream;
  late StreamSubscription responsesSubscription;
  bool allParticipantsAnswered = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
    _listenToSession();
  }

  @override
  void dispose() {
    responsesSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    try {
      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (!quizDoc.exists) {
        _showError("Quiz introuvable");
        return;
      }

      final quiz = Quiz.fromFirestore(quizDoc);

      if (quiz.questions == null || quiz.questions!.isEmpty) {
        _showError("Aucune question trouvée dans ce quiz");
        return;
      }

      setState(() {
        questions = quiz.questions!;
        isLoading = false;
      });

      _listenToResponses();
    } catch (e) {
      _showError("Erreur lors du chargement du quiz: $e");
    }
  }

  void _listenToSession() {
    FirebaseFirestore.instance
        .collection('quizSessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        if (mounted) {
          setState(() {
            session = QuizSession.fromFirestore(snapshot);
          });
        }
      }
    });
  }

  void _listenToResponses() {
    responsesStream = FirebaseFirestore.instance
        .collection('responses')
        .where('sessionId', isEqualTo: widget.sessionId)
        .where('questionId', isEqualTo: questions[currentQuestionIndex].id)
        .snapshots();

    responsesSubscription = responsesStream.listen((snapshot) {
      if (session == null) return;

      final responses = snapshot.docs.map((doc) => Response.fromFirestore(doc)).toList();

      Map<String, Map<String, int>> scores = {};

      for (var response in responses) {
        if (!scores.containsKey(response.participantId)) {
          scores[response.participantId] = {
            'score': 0,
            'questionCount': 0,
          };
        }
        scores[response.participantId]!['score'] =
            (scores[response.participantId]!['score'] ?? 0) + response.score.toInt(); // Cast to int here
        scores[response.participantId]!['questionCount'] =
            (scores[response.participantId]!['questionCount'] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          participantScores = scores;
          allParticipantsAnswered = session!.participants.every(
            (participant) =>
                scores.containsKey(participant.id) &&
                scores[participant.id]!['questionCount']! > 0,
          );
        });
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _goToNextQuestion() async {
    if (currentQuestionIndex >= questions.length - 1) {
      await _endQuiz();
      return;
    }

    responsesSubscription.cancel();

    setState(() {
      currentQuestionIndex++;
      allParticipantsAnswered = false;
    });

    try {
      await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(widget.sessionId)
          .update({
        'activeQuestionId': questions[currentQuestionIndex].id,
        'state': QuestionState.answeringQuestion.index,
      });

      _listenToResponses();
    } catch (e) {
      _showError("Erreur lors du passage à la question suivante: $e");
    }
  }

  Future<void> _endQuiz() async {
    try {
      final now = DateTime.now();

      await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(widget.sessionId)
          .update({
        'state': QuestionState.displayingResult.index,
        'isFinished': true,
        'endTime': now,
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultPage( // Use ResultPage, not QuizResultPage
              quizId: widget.quizId,
              sessionId: widget.sessionId,
            ),
          ),
        );
      }
    } catch (e) {
      _showError("Erreur lors de la fin du quiz: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || session == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Chargement...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1}/${questions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentQuestion.text,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...currentQuestion.options.map((option) {
              return Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: option.id == currentQuestion.correctOptionId
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: option.id == currentQuestion.correctOptionId
                        ? Colors.green
                        : Colors.grey.shade400,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(option.text, style: TextStyle(fontSize: 18)),
                    ),
                    if (option.id == currentQuestion.correctOptionId)
                      Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 30),
            Text(
              "Participants ayant répondu: ${participantScores.length}/${session!.participants.length}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: session!.participants.length,
                itemBuilder: (context, index) {
                  final participant = session!.participants[index];
                  final hasAnswered = participantScores.containsKey(participant.id);

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(participant.username[0].toUpperCase()),
                    ),
                    title: Text(participant.username),
                    trailing: hasAnswered
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : Icon(Icons.hourglass_empty, color: Colors.orange),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: allParticipantsAnswered ? _goToNextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  currentQuestionIndex >= questions.length - 1
                      ? "Terminer le Quiz"
                      : "Question suivante",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
