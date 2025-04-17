import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:mentor_quiz/models/quizsession.dart';
import 'package:mentor_quiz/models/participant.dart';
import 'package:mentor_quiz/screens/participant/ParticipantQuizPage.dart';

class JoinQuizPage extends StatefulWidget {
  @override
  _JoinQuizPageState createState() => _JoinQuizPageState();
}

class _JoinQuizPageState extends State<JoinQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  void _joinQuiz() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  String username = _usernameController.text.trim();
  String code = _codeController.text.trim().toUpperCase();

  try {
    // S'authentifier anonymement pour avoir les permissions nécessaires
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // Rechercher le quiz avec ce code de participation
    QuerySnapshot quizQuery = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('participationCode', isEqualTo: code)
        .limit(1)
        .get();

    if (quizQuery.docs.isEmpty) {
      _showError("Code de participation invalide.");
      return;
    }

    DocumentSnapshot quizDoc = quizQuery.docs.first;
    String quizId = quizDoc.id;

    // Rechercher une session active pour ce quiz
    QuerySnapshot sessionQuery = await FirebaseFirestore.instance
        .collection('quizSessions')
        .where('quizId', isEqualTo: quizId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (sessionQuery.docs.isEmpty) {
      _showError("Aucune session active trouvée pour ce quiz.");
      return;
    }

    DocumentSnapshot sessionDoc = sessionQuery.docs.first;
    QuizSession session = QuizSession.fromFirestore(sessionDoc);
    
    // Vérifier si la session est en attente de participants
    if (session.state != QuestionState.waitingForParticipants) {
      _showError("Ce quiz a déjà commencé.");
      return;
    }

    // Vérifier si le nom d'utilisateur est déjà pris
    bool usernameExists = session.participants.any((p) => p.username.toLowerCase() == username.toLowerCase());
    if (usernameExists) {
      _showError("Ce nom d'utilisateur est déjà utilisé. Veuillez en choisir un autre.");
      return;
    }

    // Créer un nouveau participant
    var participantId = const Uuid().v4();
    Participant newParticipant = Participant(
      id: participantId,
      username: username,
      iconUrl: "", // ou générer une URL d'icône aléatoire
      totalScore: 0,
    );

    // Utiliser une opération atomique pour ajouter le participant
    await FirebaseFirestore.instance
        .collection('quizSessions')
        .doc(session.id)
        .update({
      'participants': FieldValue.arrayUnion([newParticipant.toMap()]),
    });

    // Rediriger vers la page du quiz pour le participant
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ParticipantQuizPage(
          sessionId: session.id,
          participantId: participantId,
        ),
      ),
    );
  } catch (e) {
    print("Erreur détaillée: $e");
    _showError("Erreur lors de la tentative de connexion : ${e.toString().split(']').last}");
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rejoindre un Quiz"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Entrez votre nom et le code de participation",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Nom d'utilisateur",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom d\'utilisateur';
                  }
                  if (value.length < 3) {
                    return 'Le nom doit comporter au moins 3 caractères';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: "Code de participation",
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le code de participation';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.characters,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinQuiz,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "REJOINDRE LE QUIZ",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}