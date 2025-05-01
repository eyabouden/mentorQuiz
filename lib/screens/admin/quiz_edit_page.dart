import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentor_quiz/models/option.dart';
import 'package:mentor_quiz/models/quiz.dart';
import 'package:mentor_quiz/models/question.dart';
import 'package:mentor_quiz/screens/admin/my_quizzes_page.dart';
import '../../services/quiz_service.dart';
import '../../widgets/pop_click_enrg.dart';
import '../../widgets/question_list.dart';
import '../../widgets/question_editor.dart';
import '../../widgets/question_setting_panel.dart';
import '../../widgets/themes_panel.dart';
// Uncomment the following import if your logo is an SVG file.
// import 'package:flutter_svg/flutter_svg.dart';

class QuizEditPage extends StatefulWidget {
  final String quizId;

  QuizEditPage({required this.quizId});

  @override
  _QuizEditPageState createState() => _QuizEditPageState();
}

class _QuizEditPageState extends State<QuizEditPage> {
  final TextEditingController _quizTitleController = TextEditingController();
  List<Question> _quizQuestions = []; // Initialized to an empty list.
  final QuizService quizService = QuizService();
  int _selectedQuestionIndex = -1;
  bool _showThemesPanel = false;
  String _selectedBackgroundImage = '';
  bool _isLoading = true;

  final List<String> _backgroundImages = [
    'assets/images/themes/theme1.jpg',
    'assets/images/themes/theme2.jpg',
    'assets/images/themes/theme3.jpg',
    'assets/images/themes/theme4.jpg',
    'assets/images/themes/theme5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  void _fetchQuizData() async {
    setState(() {
      _isLoading = true;
    });

    var quizDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .get();
    if (quizDoc.exists) {
      var data = quizDoc.data()!;
      setState(() {
        _quizTitleController.text = data['title'];
        _quizQuestions = List<Question>.from(data['questions'].map((q) => Question.fromMap(q)));
        _isLoading = false;

        // Select the first question if available
        if (_quizQuestions.isNotEmpty) {
          _selectedQuestionIndex = 0;
          _selectedBackgroundImage = _quizQuestions[0].backgroundImage ?? '';
        }
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Quiz not found!")),
      );
    }
  }

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
              Divider(),
              ListTile(
                leading: Icon(Icons.leaderboard, color: Colors.orange),
                title: Text("Classement"),
                subtitle: Text("Slide de classement"),
                onTap: () {
                  Navigator.pop(context);
                  _addSlide('Ranking');
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
        correctOptionId = options[0].id; // Default correct option
      } else if (questionType == 'True/False') {
        String trueId = 'true-$questionId';
        String falseId = 'false-$questionId';
        options.add(Option(id: trueId, text: "Vrai"));
        options.add(Option(id: falseId, text: "Faux"));
        correctOptionId = trueId; // "Vrai" is correct by default
      } else if (questionType == 'Ranking') {
        // For ranking slides, we don't need options or correctOptionId
        options = [];
        correctOptionId = '';
      }

      Question newQuestion = Question(
        id: questionId,
        text: "",
        options: options,
        correctOptionId: correctOptionId,
        timeAllowed: 30,
        questionType: questionType,
        backgroundImage: '', // Default background image is empty.
        points: 0, // Default points value.
      );

      // Add the new question to the quiz
      _quizQuestions.add(newQuestion);
      _selectedQuestionIndex = _quizQuestions.length - 1;
    });
  }

  void _removeSlide(int questionIndex) {
    setState(() {
      _quizQuestions.removeAt(questionIndex);
      // Adjust the selected index if necessary
      if (_selectedQuestionIndex >= _quizQuestions.length) {
        _selectedQuestionIndex =
            _quizQuestions.isEmpty ? -1 : _quizQuestions.length - 1;
      }
    });
  }

  void _onQuestionReordered(int oldIndex, int newIndex) {
    setState(() {
      final Question item = _quizQuestions.removeAt(oldIndex);
      _quizQuestions.insert(newIndex, item);
    });
  }

  void _onQuestionTextChanged(String text) {
    setState(() {
      _quizQuestions[_selectedQuestionIndex].text = text;
    });
  }

  void _onCorrectOptionChanged(String optionId) {
    setState(() {
      _quizQuestions[_selectedQuestionIndex].correctOptionId = optionId;
    });
  }

  void _onOptionTextChanged(int optionIndex, String text) {
    setState(() {
      _quizQuestions[_selectedQuestionIndex].options[optionIndex].text = text;
    });
  }

  void _onTimeChanged(int time) {
    setState(() {
      _quizQuestions[_selectedQuestionIndex].timeAllowed = time;
    });
  }

  void _onPointsChanged(int points) {
    setState(() {
      _quizQuestions[_selectedQuestionIndex].points = points;
    });
  }

  void _onThemeSelected(String imagePath) {
    setState(() {
      _selectedBackgroundImage = imagePath;
      _quizQuestions[_selectedQuestionIndex].backgroundImage = imagePath;
    });
  }

  Future<void> _saveUpdatedQuiz() async {
    try {
      // Check if user is logged in
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : utilisateur non connecté.")),
        );
        return;
      }

      // Check if quiz title is empty
      if (_quizTitleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : veuillez donner un nom au quiz.")),
        );
        return;
      }

      // Check if there are questions
      if (_quizQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ajoutez au moins une question.")),
        );
        return;
      }
      
      // Create a new Quiz object using the existing quizId for updates
          Quiz updatedQuiz = Quiz(
          id: widget.quizId,
          title: _quizTitleController.text,
          createdAt: DateTime.now(),  // Utilise la date de création existante si tu veux la conserver
          questions: _quizQuestions,
          updatedAt: DateTime.now(),
          userId: FirebaseAuth.instance.currentUser?.uid ?? '', // Ajoute l'ID de l'utilisateur
        );

      // Save the quiz to Firestore (merge: true updates only provided fields)
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .set(updatedQuiz.toFirestore(), SetOptions(merge: true));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Quiz mis à jour avec succès!")),
      );

      // Display the popup with quiz info
      showQuizPopup(_quizTitleController.text, widget.quizId);
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour du quiz : $e")),
      );
    }
  }

  void showQuizPopup(String quizName, String quizId) {
    showDialog(
      context: context,
      builder: (context) {
        return QuizPopup(
          quizName: quizName,
          quizId: quizId,
          participationCode: "",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Modification du Quiz"),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              // If using an SVG for your logo, uncomment the next line and comment out Image.asset.
              // child: SvgPicture.asset('assets/images/isi.svg', height: 40),
              child: Image.asset(
                'assets/images/isi.svg', // Ensure this is not actually an SVG, or use flutter_svg as needed.
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
              child: Text("Thèmes",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: _showThemesPanel
                    ? Colors.green[700]
                    : Colors.green,
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
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: TextButton(
              onPressed: _saveUpdatedQuiz,
              child: Text("Enregistrer",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
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
                right: BorderSide(
                    color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: QuestionList(
              questions: _quizQuestions,
              selectedQuestionIndex: _selectedQuestionIndex,
              onQuestionSelected: (index) {
                setState(() {
                  _selectedQuestionIndex = index;
                  _selectedBackgroundImage = _quizQuestions[index].backgroundImage ?? '';
                });
              },
              onQuestionDeleted: _removeSlide,
              onAddQuestion: _showQuestionTypeDialog,
              onQuestionReordered: _onQuestionReordered,
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
              child: _selectedQuestionIndex >= 0 &&
                      _selectedQuestionIndex < _quizQuestions.length
                  ? QuestionEditor(
                      question: _quizQuestions[_selectedQuestionIndex],
                      onQuestionTextChanged: _onQuestionTextChanged,
                      onCorrectOptionChanged: _onCorrectOptionChanged,
                      onOptionTextChanged: _onOptionTextChanged,
                      selectedBackgroundImage: _selectedBackgroundImage,
                    )
                  : Center(
                      child: Text(
                        "Aucune question sélectionnée. Créez une nouvelle question ou sélectionnez une existante.",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ),
          // Right section - Theme and Question Settings
          Container(
            width: 250,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                left: BorderSide(
                    color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: _showThemesPanel
                ? ThemesPanel(
                    backgroundImages: _backgroundImages,
                    selectedBackgroundImage: _selectedBackgroundImage,
                    onThemeSelected: _onThemeSelected,
                  )
                : _selectedQuestionIndex >= 0 && _selectedQuestionIndex < _quizQuestions.length
                    ? QuestionSettingPanel(
                        question: _quizQuestions[_selectedQuestionIndex],
                        questionIndex: _selectedQuestionIndex,
                        onTimeChanged: _onTimeChanged,
                        onPointsChanged: _onPointsChanged,
                      )
                    : Center(
                        child: Text(
                          "Sélectionnez un slide pour afficher et modifier ses réglages",
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
