import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class QuizHistoryPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizHistoryPage({
    Key? key,
    required this.quizId,
    required this.quizTitle,
  }) : super(key: key);

  @override
  _QuizHistoryPageState createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> sessionHistory = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizHistory();
  }

  Future<void> _loadQuizHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Récupérer toutes les sessions pour ce quiz
      // Version simplifiée sans tri par date (pour éviter l'erreur d'index)
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('quizSessions')
          .where('quizId', isEqualTo: widget.quizId)
          .get();

      List<Map<String, dynamic>> history = [];

      for (var sessionDoc in sessionsSnapshot.docs) {
        final sessionData = sessionDoc.data();
        final String sessionId = sessionDoc.id;
        final DateTime? sessionDate = sessionData['startTime']?.toDate();
        
        // Pour chaque session, récupérer les réponses des participants
        final responsesSnapshot = await FirebaseFirestore.instance
            .collection('responses')
            .where('sessionId', isEqualTo: sessionId)
            .get();

        // Calculer les scores par participant
        Map<String, int> participantScores = {};
        Map<String, String> participantNames = {};

        // Récupérer les noms des participants depuis la session
        if (sessionData['participants'] != null) {
          for (var participant in sessionData['participants']) {
            if (participant is Map) {
              String? id = participant['id'];
              String? username = participant['username'];
              if (id != null && username != null) {
                participantNames[id] = username;
              }
            }
          }
        }

        // Calculer les scores
        for (var doc in responsesSnapshot.docs) {
          final data = doc.data();
          final participantId = data['participantId'];
          final score = (data['score'] ?? 0) as int;
          
          participantScores[participantId] = (participantScores[participantId] ?? 0) + score;
        }

        // Créer une liste de participants avec leurs scores
        List<Map<String, dynamic>> participants = [];
        participantScores.forEach((participantId, score) {
          participants.add({
            'id': participantId,
            'name': participantNames[participantId] ?? 'Participant inconnu',
            'score': score,
          });
        });

        // Trier les participants par score (du plus élevé au plus bas)
        participants.sort((a, b) => b['score'].compareTo(a['score']));

        history.add({
          'sessionId': sessionId,
          'date': sessionDate ?? DateTime.now(),
          'participants': participants,
          'participantCount': participants.length,
        });
      }

      // Trier manuellement les sessions par date (les plus récentes en premier)
      history.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        sessionHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erreur lors du chargement de l'historique: $e";
        isLoading = false;
      });
      print("Error loading quiz history: $e");
      
      // Afficher un dialogue avec l'erreur et un lien pour créer l'index
      if (mounted && e.toString().contains("requires an index")) {
        _showCreateIndexDialog(e.toString());
      }
    }
  }

  void _showCreateIndexDialog(String errorMessage) {
    // Extraire l'URL de création d'index de l'erreur si possible
    String indexUrl = "";
    RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    Match? match = urlRegex.firstMatch(errorMessage);
    if (match != null) {
      indexUrl = match.group(0) ?? "";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Index Firebase requis"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Cette fonctionnalité nécessite un index composé dans Firebase Firestore."),
              SizedBox(height: 10),
              Text("Veuillez suivre ces étapes:"),
              SizedBox(height: 5),
              Text("1. Copiez l'URL ci-dessous"),
              SizedBox(height: 5),
              Text("2. Ouvrez-la dans un navigateur"),
              SizedBox(height: 5),
              Text("3. Connectez-vous à Firebase et cliquez sur 'Créer l'index'"),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.grey[200],
                child: SelectableText(
                  indexUrl.isNotEmpty 
                      ? indexUrl 
                      : "URL non disponible, consultez les journaux pour plus d'informations",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Fermer"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Détails de la session"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: session['participants'].length,
              itemBuilder: (context, index) {
                final participant = session['participants'][index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text((index + 1).toString()),
                    backgroundColor: index == 0 ? Colors.amber : Colors.blue,
                  ),
                  title: Text(participant['name']),
                  trailing: Text("${participant['score']} points", 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text("Fermer"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSession(String sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Supprimer cette session"),
          content: Text("Êtes-vous sûr de vouloir supprimer cet historique de session ? Cette action est irréversible."),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Supprimer", style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteSession(sessionId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      // Supprimer d'abord toutes les réponses liées à cette session
      final responsesSnapshot = await FirebaseFirestore.instance
          .collection('responses')
          .where('sessionId', isEqualTo: sessionId)
          .get();
          
      for (var doc in responsesSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('responses')
            .doc(doc.id)
            .delete();
      }
      
      // Puis supprimer la session elle-même
      await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(sessionId)
          .delete();
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Session supprimée avec succès")),
      );
      
      // Rafraîchir l'historique
      _loadQuizHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la suppression: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historique: ${widget.quizTitle}"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadQuizHistory,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadQuizHistory,
              child: Text("Réessayer"),
            ),
          ],
        ),
      );
    }

    if (sessionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 70, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "Aucune session trouvée pour ce quiz",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sessionHistory.length,
      itemBuilder: (context, index) {
        var session = sessionHistory[index];
        String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(session['date']);
        
        int participantCount = session['participantCount'];
        String topParticipantName = participantCount > 0 
            ? session['participants'][0]['name'] 
            : 'Aucun participant';
        int topScore = participantCount > 0 
            ? session['participants'][0]['score'] 
            : 0;
            
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.event_note, color: Colors.blue),
                title: Text("Session du $formattedDate"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Participants: $participantCount"),
                    if (participantCount > 0)
                      Text("Meilleur score: $topParticipantName ($topScore pts)"),
                  ],
                ),
                isThreeLine: true,
                onTap: () => _showSessionDetails(session),
              ),
              Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.info_outline),
                    label: Text("Détails"),
                    onPressed: () => _showSessionDetails(session),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text("Supprimer"),
                    onPressed: () => _confirmDeleteSession(session['sessionId']),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}