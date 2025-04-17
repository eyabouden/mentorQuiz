import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mentor_quiz/screens/admin/quiz_edit_page.dart';
import 'package:mentor_quiz/screens/admin/create_quiz_page.dart';
import 'package:mentor_quiz/screens/admin/quizcodeandqr.dart';

class MyQuizzesPage extends StatefulWidget {
  @override
  _MyQuizzesPageState createState() => _MyQuizzesPageState();
}

class _MyQuizzesPageState extends State<MyQuizzesPage> {
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;
  String? _errorMessage;

  void _fetchQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        var quizData = await FirebaseFirestore.instance
            .collection('quizzes')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

        if (mounted) {
          setState(() {
            _quizzes = quizData.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              data['createdAt'] = data['createdAt']?.toDate();
              return data;
            }).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "Erreur lors du chargement des quiz: $e";
            _isLoading = false;
          });
        }
        print("Error fetching quizzes: $e");
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = "Veuillez vous connecter pour voir vos quiz";
          _isLoading = false;
        });
      }
      print('No user is logged in');
    }
  }

  void _confirmDeleteQuiz(String quizId, String quizTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Supprimer le quiz"),
          content: Text("Êtes-vous sûr de vouloir supprimer '$quizTitle'?"),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Supprimer", style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteQuiz(quizId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteQuiz(String quizId) async {
    try {
      // Vérifier s'il existe des sessions actives
      var sessionsSnapshot = await FirebaseFirestore.instance
          .collection('quizSessions')
          .where('quizId', isEqualTo: quizId)
          .get();
      
      // Supprimer les sessions liées
      for (var doc in sessionsSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('quizSessions')
            .doc(doc.id)
            .delete();
      }
      
      // Supprimer le quiz
      await FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Quiz supprimé avec succès")),
      );
      
      // Rafraîchir la liste
      _fetchQuizzes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la suppression: $e")),
      );
    }
  }

  void _startQuiz(Map<String, dynamic> quiz) {
    // Générer un code de participation aléatoire
    String participationCode = quiz['participationCode'];
    
    // Mettre à jour le quiz avec le nouveau code de participation
    FirebaseFirestore.instance
        .collection('quizzes')
        .doc(quiz['id'])
        .update({'participationCode': participationCode})
        .then((_) {
          // Naviguer vers la page d'accès avec le code de participation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizAccessPage(
                quizName: quiz['title'] ?? 'Quiz Sans Titre',
                quizId: quiz['id'],
                participationCode: participationCode,
              ),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors du démarrage du quiz: $error")),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mes Quiz"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchQuizzes,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateQuizPage()),
          ).then((_) {
            // Refresh quiz list when returning from create page
            _fetchQuizzes();
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        tooltip: 'Créer un Nouveau Quiz',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchQuizzes,
              child: Text("Réessayer"),
            ),
          ],
        ),
      );
    }

    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 70, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "Vous n'avez pas encore créé de quiz",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("Créer un Quiz"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateQuizPage()),
                ).then((_) => _fetchQuizzes());
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        var quiz = _quizzes[index];
        String formattedDate = quiz['createdAt'] != null
            ? DateFormat('dd/MM/yyyy').format(quiz['createdAt'])
            : 'Date inconnue';
            
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 3,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.quiz, color: Colors.blue, size: 40),
                title: Text(
                  quiz['title'] ?? 'Quiz Sans Titre',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Créé le: $formattedDate"),
                    Text("Questions: ${(quiz['questions'] as List?)?.length ?? 0}"),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizEditPage(quizId: quiz['id']),
                    ),
                  ).then((_) => _fetchQuizzes());
                },
              ),
              Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    label: Text("Modifier"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizEditPage(quizId: quiz['id']),
                        ),
                      ).then((_) => _fetchQuizzes());
                    },
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.play_arrow, color: Colors.green),
                    label: Text("Démarrer"),
                    onPressed: () => _startQuiz(quiz),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text("Supprimer"),
                    onPressed: () => _confirmDeleteQuiz(
                      quiz['id'],
                      quiz['title'] ?? 'Quiz Sans Titre',
                    ),
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