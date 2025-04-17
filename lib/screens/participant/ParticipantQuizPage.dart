import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure this import exists
import 'package:mentor_quiz/models/quizsession.dart';
import 'package:mentor_quiz/models/reponse.dart';
import 'package:mentor_quiz/models/participant.dart';
import 'package:mentor_quiz/models/question.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class ParticipantQuizPage extends StatefulWidget {
  final String sessionId;
  final String participantId;

  ParticipantQuizPage({required this.sessionId, required this.participantId});

  @override
  _ParticipantQuizPageState createState() => _ParticipantQuizPageState();
}

class _ParticipantQuizPageState extends State<ParticipantQuizPage> {
  QuizSession? _session;
  Participant? _participant;
  Question? _currentQuestion;
  bool _isAnswering = false;
  bool _hasAnsweredCurrentQuestion = false;
  int _totalScore = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  
  // Abonnements pour les streams Firestore
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  StreamSubscription<QuerySnapshot>? _questionsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToSession();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _questionsSubscription?.cancel();
    super.dispose();
  }

  void _listenToSession() {
    _sessionSubscription = FirebaseFirestore.instance
        .collection('quizSessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        _showError("La session n'existe plus");
        return;
      }

      final session = QuizSession.fromFirestore(snapshot);
      
      try {
        final participant = session.participants.firstWhere(
          (p) => p.id == widget.participantId,
        );
        
        setState(() {
          _session = session;
          _participant = participant;
        });
        
        // Load quiz info if we haven't already
        if (_totalQuestions == 0) {
          _loadQuizInfo();
        }
        
        // Si la session change d'état, réagir en conséquence
        if (session.state == QuestionState.answeringQuestion) {
          // Vérifier si la question active a changé
          if (_currentQuestion == null || _currentQuestion!.id != session.activeQuestionId) {
            _loadQuestion(session.activeQuestionId);
            setState(() {
              _hasAnsweredCurrentQuestion = false;
            });
          }
        } else if (session.state == QuestionState.displayingResult) {
        
        }
      } catch (e) {
        _showError("Participant non trouvé dans la session");
      }
    });
  }

  void _loadQuizInfo() async {
    try {
      DocumentSnapshot quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(_session!.quizId)
          .get();
    
      if (quizDoc.exists) {
        final quizData = quizDoc.data() as Map<String, dynamic>?;
        
        if (quizData != null && quizData.containsKey('questions')) {
          final questionsList = quizData['questions'] as List;
          setState(() {
            _totalQuestions = questionsList.length;
          });
        }
      }
    } catch (e) {
      print("Error loading quiz info: $e");
    }
  }

  void _loadQuestion(String questionId) async {
    try {
      // Charger le document quiz
      DocumentSnapshot quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(_session!.quizId)
          .get();
    
      if (!quizDoc.exists) {
        _showError("Quiz non trouvé");
        return;
      }
      
      // Récupérer les données du quiz
      final quizData = quizDoc.data() as Map<String, dynamic>?;
      
      if (quizData == null || !quizData.containsKey('questions')) {
        _showError("Aucune question trouvée dans ce quiz");
        return;
      }
      
      // Trouver la question dans la liste des questions du quiz
      final questionsList = quizData['questions'] as List;
      Map<String, dynamic>? questionData;
      
      for (var q in questionsList) {
        if (q['id'] == questionId) {
          questionData = Map<String, dynamic>.from(q);
          break;
        }
      }
      
      if (questionData == null) {
        _showError("Question non trouvée");
        return;
      }
      
      final question = Question.fromMap(questionData);
      
      setState(() {
        _currentQuestion = question;
      });
    } catch (e) {
      _showError("Erreur lors du chargement de la question: $e");
    }
  }

  void _submitAnswer(String answerId) async {
    if (_isAnswering || _hasAnsweredCurrentQuestion || 
        _currentQuestion == null || _session == null || _participant == null) 
      return;

    setState(() {
      _isAnswering = true;
    });

    try {
      final question = _currentQuestion!;
      final isCorrect = answerId == question.correctOptionId;
      final gainedScore = isCorrect ? question.points : 0;

      if (isCorrect) {
        setState(() {
          _correctAnswers++;
        });
      }

      setState(() {
        _totalScore += gainedScore;
        _hasAnsweredCurrentQuestion = true;
      });

      // Mettre à jour le score du participant dans la session
      final updatedParticipants = _session!.participants.map((p) {
        if (p.id == widget.participantId) {
          return Participant(
            id: p.id,
            username: p.username,
            iconUrl: p.iconUrl,
            totalScore: p.totalScore + gainedScore,
          );
        }
        return p;
      }).toList();

      // Mettre à jour le score du participant en Firestore
      await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(widget.sessionId)
          .update({
        'participants': updatedParticipants.map((p) => p.toMap()).toList(),
      });

      // Enregistrer la réponse
           final response = Response(
          id: const Uuid().v4(),
          sessionId: widget.sessionId,
          questionId: question.id,
          participantId: widget.participantId,
          answerId: answerId,
          score: gainedScore,
          submittedAt: DateTime.now(),
          isCorrect: isCorrect, // Assurez-vous de passer cette valeur ici
        );

      await FirebaseFirestore.instance
          .collection('responses')
          .doc(response.id)
          .set(response.toFirestore());

    } catch (e) {
      _showError("Erreur lors de la soumission de la réponse: $e");
    } finally {
      setState(() {
        _isAnswering = false;
      });
    }
  }

 

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null || _participant == null) {
      return Scaffold(
        appBar: AppBar(title: Text("En attente de début...")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("En attente du démarrage du quiz..."),
            ],
          ),
        ),
      );
    }

    if (_session!.state == QuestionState.waitingForParticipants) {
      return Scaffold(
        appBar: AppBar(title: Text("En attente de début")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, size: 64, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                "Bienvenue, ${_participant!.username}!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "En attente que l'organisateur démarre le quiz...",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Chargement de la question...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz en cours"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _currentQuestion!.text,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            
            Expanded(
              child: ListView.builder(
                itemCount: _currentQuestion!.options.length,
                itemBuilder: (context, index) {
                  final option = _currentQuestion!.options[index];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      onPressed: _hasAnsweredCurrentQuestion
                          ? null
                          : () => _submitAnswer(option.id),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: _hasAnsweredCurrentQuestion && option.id == _currentQuestion!.correctOptionId
                            ? Colors.green
                            : null,
                        disabledBackgroundColor: _hasAnsweredCurrentQuestion 
                            ? (option.id == _currentQuestion!.correctOptionId 
                                ? Colors.green.shade200 
                                : Colors.grey.shade300)
                            : Colors.grey.shade300,
                      ),
                      child: Text(
                        option.text,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            if (_hasAnsweredCurrentQuestion)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "Réponse enregistrée! En attente des autres participants...",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
            SizedBox(height: 20),
            
            Text(
              "Score actuel: $_totalScore",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}