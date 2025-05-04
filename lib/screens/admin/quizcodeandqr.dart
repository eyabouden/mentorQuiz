import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/quizsession.dart';
import 'package:mentor_quiz/models/participant.dart';
import 'package:mentor_quiz/screens/admin/quiz_presentation_page.dart';
import 'package:uuid/uuid.dart';

// Classe utilitaire pour générer le lien
class QuizCodeGenerator {
  static String generateQuizLink(String quizId, String accessCode) {
    // Using Android package format to open the installed app
    return 'package://com.example.mentor_quiz/join?code=$accessCode';
  }
}

class QuizAccessPage extends StatefulWidget {
  final String quizName;
  final String quizId;
  final String participationCode;

  QuizAccessPage({
    Key? key,
    required this.quizName,
    required this.quizId,
    required this.participationCode,
  }) : super(key: key);

  @override
  _QuizAccessPageState createState() => _QuizAccessPageState();
}

class _QuizAccessPageState extends State<QuizAccessPage> {
  List<Participant> participants = [];
  String? sessionId;
  bool isCreatingSession = false;

  @override
  void initState() {
    super.initState();
    _createQuizSession(); // On attend la création avant d'écouter
  }

  Future<void> _createQuizSession() async {
    setState(() {
      isCreatingSession = true;
    });

    try {
      final newSessionId = const Uuid().v4();

      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      final quizData = quizDoc.data();
      String firstQuestionId = '';

      if (quizData != null && quizData.containsKey('questions')) {
        final questionsList = quizData['questions'] as List;
        if (questionsList.isNotEmpty) {
          firstQuestionId = questionsList[0]['id'];
        }
      }

      final session = QuizSession(
        id: newSessionId,
        quizId: widget.quizId,
        activeQuestionId: firstQuestionId,
        state: QuestionState.waitingForParticipants,
        participants: [],
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(newSessionId)
          .set(session.toFirestore());

      setState(() {
        sessionId = newSessionId;
        isCreatingSession = false;
      });

      // 🔥 Maintenant que la session existe, écouter les participants
      _listenForParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création de la session: $e')),
      );
      setState(() {
        isCreatingSession = false;
      });
    }
  }

  void _listenForParticipants() {
    if (sessionId == null) return;

    FirebaseFirestore.instance
        .collection('quizSessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final session = QuizSession.fromFirestore(snapshot);
            setState(() {
              participants = session.participants;
            });
          }
        });
  }

  Future<void> _startQuiz() async {
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session non initialisée')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(sessionId)
          .update({
        'state': QuestionState.answeringQuestion.index,
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuizPresentationPage(
            quizId: widget.quizId,
            sessionId: sessionId!,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du démarrage du quiz: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizLink = QuizCodeGenerator.generateQuizLink(
        widget.quizId, widget.participationCode);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Prêt'),
        centerTitle: true,
      ),
      body: isCreatingSession
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.quizName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Code de participation :',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.participationCode,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    QrImageView(
                      data: quizLink,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Scannez le QR code ou utilisez le code ci-dessus\npour rejoindre le quiz',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    // Participants connectés
                    if (participants.isNotEmpty) 
                      Column(
                        children: [
                          Text(
                            '${participants.length} participant${participants.length > 1 ? 's' : ''} connecté${participants.length > 1 ? 's' : ''} :',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 200,
                            width: double.infinity,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: participants.map((participant) {
                                  // Convert hex color string to Color object
                                  Color avatarColor = Color(int.parse(participant.avatarColor.replaceFirst('#', '0xFF')));
                                  
                                  return Container(
                                    width: 80,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: avatarColor.withOpacity(0.2),
                                            border: Border.all(color: avatarColor, width: 2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              participant.avatar,
                                              style: TextStyle(fontSize: 24),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          participant.username,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: participants.length >= 2 ? _startQuiz : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Text(
                        'Démarrer le Quiz',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
