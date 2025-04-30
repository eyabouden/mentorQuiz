import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/quiz.dart';
import 'package:mentor_quiz/models/question.dart';
import 'package:mentor_quiz/models/quizsession.dart';
import 'package:mentor_quiz/models/reponse.dart';
import 'package:mentor_quiz/screens/admin/ResultPage.dart';

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
  Map<String, Map<String, dynamic>> participantScores = {};
  late Stream<QuerySnapshot> responsesStream;
  StreamSubscription? responsesSubscription;
  bool allParticipantsAnswered = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
    _listenToSession();
  }

  @override
  void dispose() {
    responsesSubscription?.cancel();
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
    if (questions.isEmpty || currentQuestionIndex >= questions.length) {
      return;
    }
    
    responsesStream = FirebaseFirestore.instance
        .collection('responses')
        .where('sessionId', isEqualTo: widget.sessionId)
        .where('questionId', isEqualTo: questions[currentQuestionIndex].id)
        .snapshots();

    responsesSubscription = responsesStream.listen((snapshot) {
      if (session == null || !mounted) return;

      final responses = snapshot.docs.map((doc) => Response.fromFirestore(doc)).toList();

      Map<String, Map<String, dynamic>> scores = {};

      for (var response in responses) {
        if (!scores.containsKey(response.participantId)) {
          scores[response.participantId] = {
            'score': 0,
            'questionCount': 0,
          };
        }
        scores[response.participantId]!['score'] = 
            (scores[response.participantId]!['score'] as int) + response.score.toInt();
        scores[response.participantId]!['questionCount'] = 
            (scores[response.participantId]!['questionCount'] as int) + 1;
      }

      setState(() {
        participantScores = scores;
        allParticipantsAnswered = session!.participants.every(
          (participant) =>
              scores.containsKey(participant.id) &&
              scores[participant.id]!['questionCount']! > 0,
        );
      });
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

    responsesSubscription?.cancel();

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
            builder: (context) => QuizResultsPage(
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
        appBar: AppBar(title: const Text("Chargement...")),
        body: const Center(child: CircularProgressIndicator()),
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...currentQuestion.options.map((option) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(option.text, style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 30),
            Text(
              "Participants ayant répondu: ${participantScores.length}/${session!.participants.length}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: session!.participants.length,
                itemBuilder: (context, index) {
                  final participant = session!.participants[index];
                  final hasAnswered = participantScores.containsKey(participant.id);

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(participant.username.isNotEmpty 
                          ? participant.username[0].toUpperCase() 
                          : "?"),
                    ),
                    title: Text(participant.username),
                    trailing: hasAnswered
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.hourglass_empty, color: Colors.orange),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: allParticipantsAnswered ? _goToNextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  currentQuestionIndex >= questions.length - 1
                      ? "Terminer le Quiz"
                      : "Question suivante",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}