import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentor_quiz/models/option.dart';
import 'package:mentor_quiz/models/quiz.dart';
import 'package:mentor_quiz/models/question.dart';
import 'package:mentor_quiz/screens/admin/my_quizzes_page.dart';
import '../../services/quiz_service.dart';
import '../../widgets/pop_click_enrg.dart';
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

  void _applyThemeToCurrentSlide(String imagePath) {
    if (_selectedQuestionIndex >= 0 && _selectedQuestionIndex < _quizQuestions.length) {
      setState(() {
        _quizQuestions[_selectedQuestionIndex].backgroundImage = imagePath;
        _selectedBackgroundImage = imagePath;
      });
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Liste des questions",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _quizQuestions.length,
                    itemBuilder: (context, index) {
                      Question question = _quizQuestions[index];
                      return Card(
                        color: _selectedQuestionIndex == index
                            ? Colors.blue[100]
                            : Colors.white,
                        margin: EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text("${index + 1}",
                                style: TextStyle(
                                    color: Colors.white)),
                          ),
                          title: Text(question.text.isEmpty
                              ? "Question ${index + 1}"
                              : question.text),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSlide(index),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedQuestionIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showQuestionTypeDialog,
                  icon: Icon(Icons.add),
                  label: Text("Ajouter une Question"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
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
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                "Question",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _quizQuestions[_selectedQuestionIndex]
                                              .options
                                              .length >
                                          2
                                      ? Colors.blue[100]
                                      : Colors.green[100],
                                  borderRadius:
                                      BorderRadius.circular(15),
                                ),
                                child: Text(
                                  _quizQuestions[_selectedQuestionIndex]
                                              .options
                                              .length >
                                          2
                                      ? 'Choix Multiple'
                                      : 'Vrai ou Faux',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _quizQuestions[_selectedQuestionIndex]
                                                .options
                                                .length >
                                            2
                                        ? Colors.blue[800]
                                        : Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 16.0),
                            child: Card(
                              color: _selectedBackgroundImage.isNotEmpty
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.pink[50],
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _quizQuestions[
                                                  _selectedQuestionIndex]
                                              .text = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText:
                                            "Énoncé de la question",
                                        border:
                                            OutlineInputBorder(),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.8),
                                      ),
                                      controller:
                                          TextEditingController
                                              .fromValue(
                                        TextEditingValue(
                                          text: _quizQuestions[
                                                  _selectedQuestionIndex]
                                              .text,
                                          selection: TextSelection.collapsed(
                                              offset: _quizQuestions[
                                                      _selectedQuestionIndex]
                                                  .text
                                                  .length),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    _quizQuestions[
                                                    _selectedQuestionIndex]
                                                .options
                                                .length >
                                            2
                                        ? Column(
                                            children: [
                                              for (int i = 0;
                                                  i <
                                                      _quizQuestions[
                                                              _selectedQuestionIndex]
                                                          .options
                                                          .length;
                                                  i++)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets
                                                          .only(
                                                          bottom: 8.0),
                                                  child: Row(
                                                    children: [
                                                      Radio<String>(
                                                        value: _quizQuestions[_selectedQuestionIndex]
                                                            .options[i]
                                                            .id,
                                                        groupValue: _quizQuestions[_selectedQuestionIndex]
                                                            .correctOptionId,
                                                        onChanged:
                                                            (value) {
                                                          setState(() {
                                                            _quizQuestions[_selectedQuestionIndex]
                                                                    .correctOptionId =
                                                                value!;
                                                          });
                                                        },
                                                      ),
                                                      Expanded(
                                                        child:
                                                            TextField(
                                                          onChanged:
                                                              (value) {
                                                            setState(() {
                                                              _quizQuestions[_selectedQuestionIndex].options[i].text =
                                                                  value;
                                                            });
                                                          },
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                "Option ${i + 1}",
                                                            border:
                                                                OutlineInputBorder(),
                                                            filled:
                                                                true,
                                                            fillColor:
                                                                Colors.white.withOpacity(0.8),
                                                          ),
                                                          controller:
                                                              TextEditingController.fromValue(
                                                            TextEditingValue(
                                                              text: _quizQuestions[_selectedQuestionIndex]
                                                                  .options[i].text,
                                                              selection: TextSelection.collapsed(
                                                                  offset: _quizQuestions[_selectedQuestionIndex]
                                                                      .options[i].text.length),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(
                                                    bottom: 8.0),
                                                decoration:
                                                    BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                                child: ListTile(
                                                  leading: Radio<String>(
                                                    value: _quizQuestions[
                                                            _selectedQuestionIndex]
                                                        .options[0]
                                                        .id,
                                                    groupValue: _quizQuestions[
                                                            _selectedQuestionIndex]
                                                        .correctOptionId,
                                                    onChanged:
                                                        (value) {
                                                      setState(() {
                                                        _quizQuestions[_selectedQuestionIndex].correctOptionId =
                                                            value!;
                                                      });
                                                    },
                                                  ),
                                                  title: Text("Vrai",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                              ),
                                              Container(
                                                decoration:
                                                    BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                                child: ListTile(
                                                  leading: Radio<String>(
                                                    value: _quizQuestions[
                                                            _selectedQuestionIndex]
                                                        .options[1]
                                                        .id,
                                                    groupValue: _quizQuestions[
                                                            _selectedQuestionIndex]
                                                        .correctOptionId,
                                                    onChanged:
                                                        (value) {
                                                      setState(() {
                                                        _quizQuestions[_selectedQuestionIndex].correctOptionId =
                                                            value!;
                                                      });
                                                    },
                                                  ),
                                                  title: Text("Faux",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                ? Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thèmes disponibles",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Sélectionnez un arrière-plan pour votre question:",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                          itemCount:
                              _backgroundImages.length + 1,
                          itemBuilder:
                              (context, index) {
                            if (index == 0) {
                              return GestureDetector(
                                onTap: () => _applyThemeToCurrentSlide(''),
                                child: Card(
                                  color: Colors.white,
                                  elevation: 2,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.block,
                                          size: 40,
                                          color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text("Pas de thème",
                                          textAlign:
                                              TextAlign.center),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              String imagePath = _backgroundImages[index - 1];
                              return GestureDetector(
                                onTap: () => _applyThemeToCurrentSlide(imagePath),
                                child: Card(
                                  elevation: 2,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration:
                                            BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          image:
                                              DecorationImage(
                                            image: AssetImage(imagePath),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (_selectedBackgroundImage == imagePath)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Note: L'image sera appliquée uniquement à la question sélectionnée.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  )
                : _selectedQuestionIndex >= 0 && _selectedQuestionIndex < _quizQuestions.length
                    ? Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Réglages de la Question ${_selectedQuestionIndex + 1}",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Type de question",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        _quizQuestions[_selectedQuestionIndex].options.length > 2
                                            ? Icons.format_list_numbered
                                            : Icons.check_circle_outline,
                                        color: _quizQuestions[_selectedQuestionIndex].options.length > 2
                                            ? Colors.blue
                                            : Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _quizQuestions[_selectedQuestionIndex].options.length > 2
                                            ? "Choix Multiple"
                                            : "Vrai ou Faux",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Temps par question",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.timer, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text(
                                            "${_quizQuestions[_selectedQuestionIndex].timeAllowed} secondes",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              int? tempValue = _quizQuestions[_selectedQuestionIndex].timeAllowed;
                                              return AlertDialog(
                                                title: Text("Modifier le temps"),
                                                content: TextField(
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: "Entrez le temps en secondes",
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  controller: TextEditingController(
                                                      text: tempValue.toString()),
                                                  onChanged: (value) {
                                                    tempValue = int.tryParse(value);
                                                  },
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: Text("Annuler"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        if (tempValue != null) {
                                                          _quizQuestions[_selectedQuestionIndex].timeAllowed = tempValue!;
                                                        }
                                                        Navigator.of(context).pop();
                                                      });
                                                    },
                                                    child: Text("Enregistrer"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: Icon(Icons.edit, size: 16),
                                        tooltip: "Modifier le temps",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Points par question",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.amber),
                                          SizedBox(width: 8),
                                          Text(
                                            "${_quizQuestions[_selectedQuestionIndex].points} points",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              int pointsValue = _quizQuestions[_selectedQuestionIndex].points;
                                              return AlertDialog(
                                                title: Text("Modifier les points"),
                                                content: TextField(
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: "Entrez le nombre de points",
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  controller: TextEditingController(
                                                      text: pointsValue.toString()),
                                                  onChanged: (value) {
                                                    pointsValue = int.tryParse(value) ?? pointsValue;
                                                  },
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: Text("Annuler"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _quizQuestions[_selectedQuestionIndex].points = pointsValue;
                                                      });
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Text("Enregistrer"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: Icon(Icons.edit, size: 16),
                                        tooltip: "Modifier les points",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
