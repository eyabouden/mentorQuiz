import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/participant.dart';
import 'package:mentor_quiz/models/quizsession.dart';
import 'package:mentor_quiz/models/quiz.dart';
import 'package:mentor_quiz/models/reponse.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class ParticipantResultsPage extends StatefulWidget {
  final String sessionId;
  final String participantId;

  const ParticipantResultsPage({
    Key? key,
    required this.sessionId,
    required this.participantId,
  }) : super(key: key);

  @override
  _ParticipantResultsPageState createState() => _ParticipantResultsPageState();
}

class _ParticipantResultsPageState extends State<ParticipantResultsPage> {
  bool _isLoading = true;
  QuizSession? _session;
  Participant? _participant;
  int _rank = 0;
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _loadResults();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    try {
      // Load session data
      final sessionDoc = await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(widget.sessionId)
          .get();

      if (!sessionDoc.exists) {
        _showError("Session introuvable");
        return;
      }

      final session = QuizSession.fromFirestore(sessionDoc);
      
      // Find current participant
      final participant = session.participants.firstWhere(
        (p) => p.id == widget.participantId,
        orElse: () => throw Exception("Participant non trouvé"),
      );

      // Sort participants by score to determine rank
      final sortedParticipants = [...session.participants];
      sortedParticipants.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      
      final rank = sortedParticipants.indexWhere((p) => p.id == widget.participantId) + 1;

      // Load quiz data to get total questions
      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(session.quizId)
          .get();

      if (!quizDoc.exists) {
        _showError("Quiz introuvable");
        return;
      }

      final quizData = quizDoc.data() as Map<String, dynamic>;
      final questions = quizData['questions'] as List<dynamic>;
      final totalQuestions = questions.length;

      // Get participant's responses to calculate correct answers
      final responsesSnapshot = await FirebaseFirestore.instance
          .collection('responses')
          .where('sessionId', isEqualTo: widget.sessionId)
          .where('participantId', isEqualTo: widget.participantId)
          .get();

      int correctAnswers = 0;
      for (var doc in responsesSnapshot.docs) {
        final response = Response.fromFirestore(doc);
        if (response.isCorrect) {
          correctAnswers++;
        }
      }

      setState(() {
        _session = session;
        _participant = participant;
        _rank = rank;
        _totalQuestions = totalQuestions;
        _correctAnswers = correctAnswers;
        _isLoading = false;
      });

      // Start confetti animation if in top 3
      if (rank <= 3) {
        _confettiController.play();
      }
    } catch (e) {
      _showError("Erreur lors du chargement des résultats: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildRankBadge() {
    Color badgeColor;
    IconData iconData;
    String rankText = _rank.toString();
    
    switch (_rank) {
      case 1:
        badgeColor = Colors.amber;
        iconData = Icons.emoji_events;
        break;
      case 2:
        badgeColor = Colors.blueGrey.shade300;
        iconData = Icons.emoji_events;
        break;
      case 3:
        badgeColor = Colors.brown.shade300;
        iconData = Icons.emoji_events;
        break;
      default:
        badgeColor = Colors.blue;
        iconData = Icons.star;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              iconData,
              size: 120,
              color: badgeColor,
            ),
            Text(
              rankText,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _rank <= 3 ? Colors.white : badgeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _rank == 1
              ? "Champion!"
              : _rank == 2
                  ? "Vice-champion!"
                  : _rank == 3
                      ? "Médaille de bronze!"
                      : "${_rank}ème place",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: badgeColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chargement des résultats")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final percentCorrect = _totalQuestions > 0
        ? (_correctAnswers / _totalQuestions * 100).toInt()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Résultats du Quiz"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navigate back to home and clear stack
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Confetti animation for top 3 participants
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Participant avatar and name
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(int.parse(
                          "0xFF${_participant!.avatarColor.substring(1)}")),
                    ),
                    child: Center(
                      child: Text(
                        _participant!.avatar,
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _participant!.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Rank badge
                  _buildRankBadge(),
                  const SizedBox(height: 40),
                  
                  // Score and stats
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            "Vos statistiques",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          
                          // Total score
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Score total:",
                                style: TextStyle(fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${_participant!.totalScore} points",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          
                          // Correct answers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Réponses correctes:",
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                "$_correctAnswers / $_totalQuestions ($percentCorrect%)",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          
                          // Rank
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Classement:",
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                "$_rank / ${_session!.participants.length}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Motivational message based on performance
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getMotivationalMessage(percentCorrect, _rank),
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Share results button
                  ElevatedButton.icon(
                    onPressed: () => _shareResults(),
                    icon: const Icon(Icons.share),
                    label: const Text("Partager mes résultats"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(int percentCorrect, int rank) {
    if (rank == 1) {
      return "Félicitations! Vous êtes le champion de ce quiz! 🏆";
    } else if (rank <= 3) {
      return "Excellent travail! Vous êtes sur le podium! 🥇🥈🥉";
    } else if (percentCorrect >= 80) {
      return "Très bon score! Continuez comme ça! 👏";
    } else if (percentCorrect >= 60) {
      return "Bon travail! Vous avez bien répondu à la majorité des questions.";
    } else if (percentCorrect >= 40) {
      return "Pas mal! Continuez à pratiquer pour vous améliorer.";
    } else {
      return "Ce quiz était difficile! Ne vous découragez pas et continuez d'apprendre.";
    }
  }

  void _shareResults() {
    // This would typically use a sharing plugin
    // For now, we'll copy results to clipboard
    final message = """
J'ai terminé à la ${_rank}e place au quiz!
Score: ${_participant!.totalScore} points
Réponses correctes: $_correctAnswers/$_totalQuestions
    """;
    
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Résultats copiés dans le presse-papiers"),
        backgroundColor: Colors.green,
      ),
    );
  }
}