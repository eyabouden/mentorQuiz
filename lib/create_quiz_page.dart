import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentor_quiz/my_quizzes_page.dart';
import 'services/quiz_service.dart';

class CreateQuizPage extends StatefulWidget {
  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final TextEditingController _quizTitleController = TextEditingController();
  final List<Map<String, dynamic>> _slides = []; // Liste des slides du quiz
  final QuizService quizService = QuizService();

  // Fonction pour ajouter un slide
  void _addSlide() {
    setState(() {
      _slides.add({
        "title": "", // Titre du slide
        "questionType": 'Multiple Choice', // Type de question par défaut
        "questions": [], // Liste des questions du slide
      });
    });
  }

  // Fonction pour ajouter une question dans un slide spécifique
  void _addQuestionToSlide(int slideIndex) {
    setState(() {
      _slides[slideIndex]["questions"].add({
        "question": "", // Question vide
        "option1": "", // Option 1
        "option2": "", // Option 2
        "option3": "", // Option 3
        "option4": "", // Option 4
      });
    });
  }

  // Fonction pour sauvegarder le quiz
  Future<void> _saveQuiz() async {
    try {
      // Récupérer l'ID de l'utilisateur
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      // Vérifier si l'utilisateur est connecté
      if (userId != null) {
        // Sauvegarder le quiz avec l'ID de l'utilisateur
        await quizService.saveQuiz(_quizTitleController.text, _slides, userId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Quiz sauvegardé avec succès!")),
        );

        // Naviguer vers la page des quiz de l'utilisateur après l'enregistrement
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyQuizzesPage()), // Naviguer vers la page des quiz de l'utilisateur
        );

      } else {
        // Si l'utilisateur n'est pas connecté
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : utilisateur non connecté.")),
        );
      }
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la sauvegarde: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Créer un Quiz"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _quizTitleController,
                decoration: InputDecoration(
                  labelText: "Titre du Quiz",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Text("Slides de Quiz", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // Afficher les slides
              ListView.builder(
                shrinkWrap: true,
                itemCount: _slides.length,
                itemBuilder: (context, slideIndex) {
                  var slide = _slides[slideIndex];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre du slide
                          TextField(
                            onChanged: (value) {
                              _slides[slideIndex]["title"] = value;
                            },
                            decoration: InputDecoration(
                              labelText: "Titre du Slide ${slideIndex + 1}",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 10),

                          // Choisir le type de question pour ce slide
                          DropdownButton<String>(
                            value: slide["questionType"],
                            onChanged: (value) {
                              setState(() {
                                _slides[slideIndex]["questionType"] = value!;
                              });
                            },
                            items: <String>['Multiple Choice', 'True/False', 'Text Response']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),

                          SizedBox(height: 20),

                          // Afficher les questions pour ce slide
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: slide["questions"].length,
                            itemBuilder: (context, questionIndex) {
                              var question = slide["questions"][questionIndex];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      // Question
                                      TextField(
                                        onChanged: (value) {
                                          _slides[slideIndex]["questions"][questionIndex]["question"] = value;
                                        },
                                        decoration: InputDecoration(
                                          labelText: "Question ${questionIndex + 1}",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      SizedBox(height: 10),

                                      // Afficher les options selon le type de question
                                      if (slide["questionType"] == 'Multiple Choice')
                                        for (int i = 1; i <= 4; i++)
                                          TextField(
                                            onChanged: (value) {
                                              _slides[slideIndex]["questions"][questionIndex]["option$i"] = value;
                                            },
                                            decoration: InputDecoration(
                                              labelText: "Option $i",
                                              border: OutlineInputBorder(),
                                            ),
                                          )
                                      else if (slide["questionType"] == 'True/False')
                                        Column(
                                          children: [
                                            ListTile(
                                              title: Text("Vrai"),
                                              leading: Radio<String>(
                                                value: 'True',
                                                groupValue: _slides[slideIndex]["questions"][questionIndex]["option1"],
                                                onChanged: (String? value) {
                                                  setState(() {
                                                    _slides[slideIndex]["questions"][questionIndex]["option1"] = value!;
                                                  });
                                                },
                                              ),
                                            ),
                                            ListTile(
                                              title: Text("Faux"),
                                              leading: Radio<String>(
                                                value: 'False',
                                                groupValue: _slides[slideIndex]["questions"][questionIndex]["option1"],
                                                onChanged: (String? value) {
                                                  setState(() {
                                                    _slides[slideIndex]["questions"][questionIndex]["option1"] = value!;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      else if (slide["questionType"] == 'Text Response')
                                        TextField(
                                          onChanged: (value) {
                                            _slides[slideIndex]["questions"][questionIndex]["option1"] = value;
                                          },
                                          decoration: InputDecoration(
                                            labelText: "Réponse libre",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _addQuestionToSlide(slideIndex),
                            child: Text("Ajouter une question"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addSlide,
                child: Text("Ajouter un Slide"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveQuiz,
                child: Text("Enregistrer le quiz"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
