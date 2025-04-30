import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentor_quiz/models/quiz.dart';
import 'package:mentor_quiz/models/question.dart';
import 'package:mentor_quiz/models/option.dart';
import 'package:mentor_quiz/screens/admin/my_quizzes_page.dart';
import '../../services/quiz_service.dart';
import '../../widgets/pop_click_enrg.dart';
import '../../widgets/question_editor.dart';
import '../../widgets/question_list.dart';
import '../../widgets/question_setting_panel.dart';
import '../../widgets/themes_panel.dart';

class CreateQuizPage extends StatefulWidget {
  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final TextEditingController _quizTitleController = TextEditingController();
  List<Question>? _quizQuestions = [];
  final QuizService quizService = QuizService();
  int _selectedQuestionIndex = -1;
  bool _showThemesPanel = false;
  String _selectedBackgroundImage = '';

  // List of available background images
  final List<String> _backgroundImages = [
    'assets/images/themes/theme1.jpg',
    'assets/images/themes/theme2.jpg',
    'assets/images/themes/theme3.jpg',
    'assets/images/themes/theme4.jpg',
    'assets/images/themes/theme5.jpg',
  ];

  // Function to show question type dialog
  void _showQuestionTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Type de Question"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.format_list_numbered, color: Colors.blue),
                title: Text("Choix Multiple"),
                subtitle: Text("4 options de réponse"),
                onTap: () {
                  Navigator.pop(context);
                  _addSlide('Multiple Choice');
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text("Vrai ou Faux"),
                subtitle: Text("2 options de réponse"),
                onTap: () {
                  Navigator.pop(context);
                  _addSlide('True/False');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler"),
            ),
          ],
        );
      },
    );
  }

void _addSlide(String questionType) {
  setState(() {
    String questionId = DateTime.now().millisecondsSinceEpoch.toString();
    List<Option> options = [];
    String correctOptionId = '';

    if (questionType == 'Multiple Choice') {
      for (int i = 1; i <= 4; i++) {
        String optionId = 'option$i-$questionId';
        options.add(Option(id: optionId, text: ""));
      }
        correctOptionId = options[0].id;
    } else if (questionType == 'True/False') {
      String trueId = 'true-$questionId';
      String falseId = 'false-$questionId';
      options.add(Option(id: trueId, text: "Vrai"));
      options.add(Option(id: falseId, text: "Faux"));
        correctOptionId = trueId;
    }

    Question newQuestion = Question(
      id: questionId,
      text: "",
      options: options,
      correctOptionId: correctOptionId,
        timeAllowed: 30,
        questionType: questionType,
    );

    _quizQuestions!.add(newQuestion);
      _selectedQuestionIndex = _quizQuestions!.length - 1;
  });
}

  void _removeSlide(int questionIndex) {
    setState(() {
      _quizQuestions!.removeAt(questionIndex);
      if (_selectedQuestionIndex >= _quizQuestions!.length) {
        _selectedQuestionIndex = _quizQuestions!.isEmpty ? -1 : _quizQuestions!.length - 1;
      }
    });
  }

  Future<void> _saveQuiz() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : utilisateur non connecté.")),
        );
        return;
      }
      
      if (_quizTitleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : veuillez donner un nom au quiz.")),
        );
        return;
      }
      
      if (_quizQuestions == null || _quizQuestions!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ajoutez au moins une question.")),
        );
        return;
      }
      
      String quizId = DateTime.now().millisecondsSinceEpoch.toString();
      
        Quiz newQuiz = Quiz(
        id: quizId,
        title: _quizTitleController.text,
        createdAt: DateTime.now(),
        questions: _quizQuestions,
        updatedAt: DateTime.now(),
        userId: currentUser.uid,
      );
      
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .set(newQuiz.toFirestore());
      
      String participationCode = _generateParticipationCode();
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .update({'participationCode': participationCode});
      
      showDialog(
        context: context,
        builder: (context) {
          return QuizPopup(
            quizName: _quizTitleController.text,
            quizId: quizId,
            participationCode: participationCode,
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement du quiz : $e")),
      );
    }
  }

  String _generateParticipationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
  
  void _applyThemeToCurrentSlide(String imagePath) {
    if (_selectedQuestionIndex >= 0 && _selectedQuestionIndex < _quizQuestions!.length) {
      setState(() {
        _selectedBackgroundImage = imagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/isi.svg',
                height: 40,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _quizTitleController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Nom du Quiz",
                  hintStyle: TextStyle(color: Colors.black),
                  border: InputBorder.none, 
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showThemesPanel = !_showThemesPanel;
                });
              },
              child: Text("Thèmes", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)), 
              style: TextButton.styleFrom(
                backgroundColor: _showThemesPanel ? Colors.green[700] : Colors.green,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => MyQuizzesPage()),
                );
              },
              child: Text(
                "Quitter", 
                style: TextStyle(
                  color: Colors.black, 
                  fontSize: 16, 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: TextButton(
              onPressed: _saveQuiz,
              child: Text("Enregistrer", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Question list
          Container(
            width: 300,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: QuestionList(
              questions: _quizQuestions!,
              selectedQuestionIndex: _selectedQuestionIndex,
              onQuestionSelected: (index) => setState(() => _selectedQuestionIndex = index),
              onQuestionDeleted: _removeSlide,
              onAddQuestion: _showQuestionTypeDialog,
              onQuestionReordered: (oldIndex, newIndex) {
                setState(() {
                  final Question question = _quizQuestions!.removeAt(oldIndex);
                  _quizQuestions!.insert(newIndex, question);
                });
              },
            ),
          ),
          
          // Middle section - Question content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                image: _selectedBackgroundImage.isNotEmpty
                    ? DecorationImage(
                        image: AssetImage(_selectedBackgroundImage),
                        fit: BoxFit.cover,
                        opacity: 0.2,
                      )
                    : null,
              ),
              child: _selectedQuestionIndex >= 0 && _selectedQuestionIndex < _quizQuestions!.length
                  ? QuestionEditor(
                      question: _quizQuestions![_selectedQuestionIndex],
                      onQuestionTextChanged: (text) {
                                        setState(() {
                          _quizQuestions![_selectedQuestionIndex].text = text;
                                        });
                                      },
                      onCorrectOptionChanged: (optionId) {
                                                        setState(() {
                          _quizQuestions![_selectedQuestionIndex].correctOptionId = optionId;
                                                        });
                                                      },
                      onOptionTextChanged: (index, text) {
                                                          setState(() {
                          _quizQuestions![_selectedQuestionIndex].options[index].text = text;
                                                          });
                                                        },
                      selectedBackgroundImage: _selectedBackgroundImage,
                    )
                  : Center(
                      child: Text(
                        "Aucune question sélectionnée. Créez une nouvelle question ou sélectionnez une existante.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ),
          
          // Right section - Time and Points or Themes
          Container(
            width: 250,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                left: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: _showThemesPanel 
                ? ThemesPanel(
                    backgroundImages: _backgroundImages,
                    selectedBackgroundImage: _selectedBackgroundImage,
                    onThemeSelected: _applyThemeToCurrentSlide,
                  )
                : _selectedQuestionIndex >= 0 && _selectedQuestionIndex < _quizQuestions!.length
                    ? QuestionSettingPanel(
                        question: _quizQuestions![_selectedQuestionIndex],
                        questionIndex: _selectedQuestionIndex,
                        onTimeChanged: (time) {
                                                      setState(() {
                            _quizQuestions![_selectedQuestionIndex].timeAllowed = time;
                                                      });
                                                    },
                        onPointsChanged: (points) {
                          // Implement points change logic
                        },
                      )
                    : Center(
                        child: Text(
                          "Sélectionnez une question pour afficher et modifier ses réglages",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}