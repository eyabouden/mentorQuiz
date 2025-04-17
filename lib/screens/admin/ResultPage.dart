import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/participant.dart';

class ResultPage extends StatefulWidget {
  final String quizId;
  final String sessionId;

  const ResultPage({
    Key? key,
    required this.quizId,
    required this.sessionId,
  }) : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> participantResults = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final sessionSnapshot = await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(widget.sessionId)
          .get();

      if (!sessionSnapshot.exists) {
        throw Exception('Session introuvable');
      }

      final participants = (sessionSnapshot.data()?['participants'] as List)
          .map((p) => Participant.fromMap(Map<String, dynamic>.from(p)))
          .toList();

      final responsesSnapshot = await FirebaseFirestore.instance
          .collection('responses')
          .where('sessionId', isEqualTo: widget.sessionId)
          .get();

      Map<String, int> participantScores = {};
      Map<String, int> correctAnswers = {};

      for (var doc in responsesSnapshot.docs) {
        final data = doc.data();
        final participantId = data['participantId'];
        final score = (data['score'] ?? 0) as int;
        final isCorrect = data['isCorrect'] ?? false;

        // Accumulate score and count correct answers
        participantScores[participantId] = (participantScores[participantId] ?? 0) + score;
        if (isCorrect) {
          correctAnswers[participantId] = (correctAnswers[participantId] ?? 0) + 1;
        }
      }

      List<Map<String, dynamic>> results = participants.map((participant) {
        return {
          'name': participant.username,
          'score': participantScores[participant.id] ?? 0,
          'correctAnswers': correctAnswers[participant.id] ?? 0,
        };
      }).toList();

      setState(() {
        participantResults = results;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des résultats: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats du Quiz'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : participantResults.isEmpty
              ? Center(child: Text("Aucun participant n'a répondu."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: participantResults.length,
                          itemBuilder: (context, index) {
                            final result = participantResults[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(result['name'][0].toUpperCase()),
                                ),
                                title: Text(result['name']),
                                subtitle: Text(
                                    '${result['score']} points | ${result['correctAnswers']} bonnes réponses'),
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: Colors.blue,
                        ),
                        child: Text('Retour à l\'accueil'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: Colors.green,
                        ),
                        child: Text('Recommencer le quiz'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
