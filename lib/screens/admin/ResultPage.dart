import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/quizsession.dart';
import 'package:mentor_quiz/models/participant.dart';
import 'package:mentor_quiz/models/quiz.dart';
import 'package:mentor_quiz/models/question.dart';
import 'package:mentor_quiz/models/reponse.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizResultsPage extends StatefulWidget {
  final String quizId;
  final String sessionId;

  const QuizResultsPage({
    Key? key,
    required this.quizId,
    required this.sessionId,
  }) : super(key: key);

  @override
  _QuizResultsPageState createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  late ConfettiController _confettiController;
  List<Participant> _participants = [];
  Map<String, int> _participantCorrectAnswers = {};
  int _totalQuestions = 0;
  bool _isLoading = true;
  QuizSession? _session;
  Quiz? _quiz;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadSessionResults();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionResults() async {
    try {
      // Load quiz
      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();
      
      if (quizDoc.exists) {
        _quiz = Quiz.fromFirestore(quizDoc);
        // Only count questions that are not ranking slides
        _totalQuestions = _quiz!.questions?.where((q) => 
          q.questionType != 'Ranking' && 
          !q.isLeaderboard
        ).length ?? 0;
      }

      // Load session
      final sessionDoc = await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(widget.sessionId)
          .get();

      if (sessionDoc.exists) {
        _session = QuizSession.fromFirestore(sessionDoc);
        
        // Load all responses for this session
        final responsesSnapshot = await FirebaseFirestore.instance
            .collection('responses')
            .where('sessionId', isEqualTo: widget.sessionId)
            .get();
            
        // Process participant answers
        Map<String, Map<String, dynamic>> participantData = {};
        
        for (var doc in responsesSnapshot.docs) {
          final response = Response.fromFirestore(doc);
          
          if (!participantData.containsKey(response.participantId)) {
            participantData[response.participantId] = {
              'score': 0,
              'correctAnswers': 0,
            };
          }
          
          participantData[response.participantId]!['score'] = 
              (participantData[response.participantId]!['score'] as int) + response.score.toInt();
              
          if (response.score > 0) {
            participantData[response.participantId]!['correctAnswers'] = 
                (participantData[response.participantId]!['correctAnswers'] as int) + 1;
          }
        }
        
        // Update participants with scores and correct answers
        if (_session != null) {
          _participants = List<Participant>.from(_session!.participants);
          _participantCorrectAnswers = {};
          
          for (var i = 0; i < _participants.length; i++) {
            final participant = _participants[i];
            if (participantData.containsKey(participant.id)) {
              _participants[i] = Participant(
                id: participant.id,
                username: participant.username,
                avatar: participant.avatar,
                avatarColor: participant.avatarColor,
                totalScore: participantData[participant.id]!['score'] as int,
              );
              
              _participantCorrectAnswers[participant.id] = 
                  participantData[participant.id]!['correctAnswers'] as int;
            }
          }
          
          // Sort participants by score
          _participants.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Play confetti for top 3 participants
      if (_participants.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _confettiController.play();
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des résultats: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700; // Gold
      case 2:
        return Colors.grey.shade400; // Silver
      case 3:
        return Colors.brown.shade300; // Bronze
      default:
        return Colors.blue.shade100;
    }
  }

  Widget _buildParticipantScoreCard(Participant participant, int rank) {
    final correctAnswers = _participantCorrectAnswers[participant.id] ?? 0;
    final percentage = _totalQuestions > 0 
        ? (correctAnswers / _totalQuestions * 100).toInt()
        : 0;
    
    String message;
    Widget animation;
    
    if (percentage >= 90) {
      message = "Excellent !";
      animation = Lottie.asset('assets/animations/trophy.json', height: 120);
    } else if (percentage >= 70) {
      message = "Très bien !";
      animation = Lottie.asset('assets/animations/star.json', height: 120);
    } else if (percentage >= 50) {
      message = "Bien joué !";
      animation = Lottie.asset('assets/animations/thump_up.json', height: 120);
    } else {
      message = "Continue tes efforts !";
      animation = Lottie.asset('assets/animations/sad.json', height: 120);
    }
    
    final bool isTopThree = rank <= 3;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (isTopThree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getRankColor(rank),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rank == 1 ? "🏆 1er" : (rank == 2 ? "🥈 2ème" : "🥉 3ème"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            animation,
            const SizedBox(height: 16),
            Text(
              participant.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Score',
                  '${participant.totalScore}',
                  Icons.stars,
                  Colors.amber,
                ),
                _buildStatItem(
                  'Bonnes réponses',
                  '$correctAnswers / $_totalQuestions',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 500.ms).scale(delay: 300.ms);
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Classement Final",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                final rank = index + 1;
                
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: rank <= 3 ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: rank <= 3 
                        ? Border.all(color: _getRankColor(rank), width: 2)
                        : null,
                    boxShadow: rank <= 3 
                        ? [BoxShadow(color: Colors.blue.shade100, blurRadius: 4)]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getRankColor(rank),
                        ),
                        child: Text(
                          "$rank",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Avatar (emoji) with background color
                      CircleAvatar(
                        backgroundColor: Color(int.parse(
                          participant.avatarColor.replaceFirst('#', '0xFF')
                        )),
                        child: Text(
                          participant.avatar,
                          style: const TextStyle(fontSize: 18),
                        ),
                        radius: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          participant.username,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        "${participant.totalScore} pts",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${_participantCorrectAnswers[participant.id] ?? 0}/$_totalQuestions)",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: (100 * index).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    if (_participants.length < 3) return const SizedBox.shrink();
    
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Second place
            if (_participants.length > 1)
              _buildPodiumPosition(
                _participants[1], 
                2, 
                Colors.grey.shade400, 
                80,
                alignment: Alignment.bottomLeft,
              ),
                
            // First place
            _buildPodiumPosition(
              _participants[0], 
              1, 
              Colors.amber.shade700, 
              100,
              alignment: Alignment.bottomCenter,
            ),
                
            // Third place
            if (_participants.length > 2)
              _buildPodiumPosition(
                _participants[2], 
                3, 
                Colors.brown.shade300, 
                60,
                alignment: Alignment.bottomRight,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumPosition(
      Participant participant, 
      int position, 
      Color color, 
      double height, 
      {Alignment alignment = Alignment.center}
  ) {
    String medal = position == 1 ? "🏆" : (position == 2 ? "🥈" : "🥉");
    Color avatarBgColor = Color(int.parse(participant.avatarColor.replaceFirst('#', '0xFF')));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            medal,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            backgroundColor: avatarBgColor.withOpacity(0.8),
            child: Text(
              participant.avatar,
              style: const TextStyle(fontSize: 20),
            ),
            radius: 24,
          ),
          const SizedBox(height: 8),
          Text(
            participant.username,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            "${participant.totalScore} pts",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "$position",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 800.ms).scaleY(begin: 0.5, end: 1, curve: Curves.elasticOut, duration: 1200.ms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Résultats du Quiz"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.amber,
                Colors.green,
                Colors.purple,
              ],
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_participants.length >= 3) _buildPodium(),
                      const SizedBox(height: 24),
                      if (_participants.isNotEmpty)
                        _buildParticipantScoreCard(_participants[0], 1),
                      const SizedBox(height: 24),
                      _buildLeaderboard(),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.settings.name == '/my-quiz');
                        },
                        icon: const Icon(Icons.list),
                        label: const Text("Retour à l'accueil"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}