import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentor_quiz/my_quizzes_page.dart';
import 'services/quiz_service.dart';
import 'widgets/pop_click_enrg.dart';

class QuizEditPage extends StatefulWidget {
  final String quizId;

  QuizEditPage({required this.quizId});

  @override
  _QuizEditPageState createState() => _QuizEditPageState();
}

class _QuizEditPageState extends State<QuizEditPage> {
  final TextEditingController _quizTitleController = TextEditingController();
  List<Map<String, dynamic>> _slides = [];
  final QuizService quizService = QuizService();
  int _selectedSlideIndex = -1;
  bool _showThemesPanel = false;
  String _selectedBackgroundImage = '';
  bool _isLoading = true;

  // Liste des images de fond disponibles
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

    var quizDoc = await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).get();
    if (quizDoc.exists) {
      var data = quizDoc.data()!;
      setState(() {
        _quizTitleController.text = data['title'];
        _slides = List<Map<String, dynamic>>.from(data['slides']);
        _isLoading = false;
        // Select the first slide if available
        if (_slides.isNotEmpty) {
          _selectedSlideIndex = 0;
          _selectedBackgroundImage = _slides[0]["backgroundImage"] ?? '';
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
      Map<String, dynamic> newSlide = {
        "title": "",
        "questionType": questionType,
        "questions": [
          {
            "question": "",  // Question vide par défaut
          }
        ],
        "time": 30,
        "points": 1,
        "backgroundImage": _selectedBackgroundImage,
      };
      
      // Ajouter les options selon le type de question
      if (questionType == 'Multiple Choice') {
        newSlide["questions"][0]["option1"] = "";
        newSlide["questions"][0]["option2"] = "";
        newSlide["questions"][0]["option3"] = "";
        newSlide["questions"][0]["option4"] = "";
      } else if (questionType == 'True/False') {
        newSlide["questions"][0]["option1"] = "Vrai";
        newSlide["questions"][0]["option2"] = "Faux";
      }
      
      _slides.add(newSlide);
      // Sélectionner automatiquement le nouveau slide
      _selectedSlideIndex = _slides.length - 1;
    });
  }

  void _removeSlide(int slideIndex) {
    setState(() {
      _slides.removeAt(slideIndex);
      // Ajuster l'index sélectionné si nécessaire
      if (_selectedSlideIndex >= _slides.length) {
        _selectedSlideIndex = _slides.isEmpty ? -1 : _slides.length - 1;
      }
    });
  }

  Future<void> _saveUpdatedQuiz() async {
    try {
      // Vérifier si l'utilisateur est connecté
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : utilisateur non connecté.")),
        );
        return;
      }
      
      // Vérifier si le titre du quiz est vide
      if (_quizTitleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : veuillez donner un nom au quiz.")),
        );
        return;
      }
      
      // Vérifier s'il y a des slides
      if (_slides.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ajoutez au moins une question.")),
        );
        return;
      }

      // Update the quiz in Firestore
      await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).update({
        'title': _quizTitleController.text,
        'slides': _slides,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Quiz mis à jour avec succès!")),
      );

      // Display the popup with quiz info
      showQuizPopup(_quizTitleController.text, widget.quizId);
      
    } catch (e) {
      // Gérer les erreurs
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
        );
      },
    );
  }

  void _applyThemeToCurrentSlide(String imagePath) {
    if (_selectedSlideIndex >= 0 && _selectedSlideIndex < _slides.length) {
      setState(() {
        _slides[_selectedSlideIndex]["backgroundImage"] = imagePath;
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
            // Logo de l'application
            Container(
              padding: EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/isi.svg', // Chemin vers ton logo
                height: 40, // Taille du logo
              ),
            ),
            SizedBox(width: 10), // Espace entre le logo et le titre
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
                // Navigate to MyQuizzes page
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
              onPressed: _saveUpdatedQuiz,
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
          // Partie gauche - Liste des slides
          Container(
            width: 300,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Liste des slides", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: _selectedSlideIndex == index ? Colors.blue[100] : Colors.white,
                        margin: EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text("${index + 1}", style: TextStyle(color: Colors.white)),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(_slides[index]["title"].isEmpty 
                                    ? "Question ${index + 1}" 
                                    : _slides[index]["title"]),
                              ),
                              // Afficher un badge pour le type de question
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _slides[index]["questionType"] == 'Multiple Choice' 
                                      ? Colors.blue[100] 
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _slides[index]["questionType"] == 'Multiple Choice' ? 'QCM' : 'V/F',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _slides[index]["questionType"] == 'Multiple Choice' 
                                        ? Colors.blue[800] 
                                        : Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSlide(index),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSlideIndex = index;
                              // Mettre à jour l'image de fond sélectionnée en fonction du slide actuel
                              _selectedBackgroundImage = _slides[index]["backgroundImage"] ?? '';
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
                  label: Text("Ajouter un Slide"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          // Partie centrale (Contenu du slide sélectionné)
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                image: _selectedSlideIndex >= 0 && _selectedSlideIndex < _slides.length && 
                       _slides[_selectedSlideIndex]["backgroundImage"] != null && 
                       _slides[_selectedSlideIndex]["backgroundImage"].isNotEmpty
                    ? DecorationImage(
                        image: AssetImage(_slides[_selectedSlideIndex]["backgroundImage"]),
                        fit: BoxFit.cover,
                        opacity: 0.2,
                      )
                    : null,
              ),
              child: _selectedSlideIndex >= 0 && _selectedSlideIndex < _slides.length
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                "Question",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 10),
                              // Afficher le type de question
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _slides[_selectedSlideIndex]["questionType"] == 'Multiple Choice' 
                                      ? Colors.blue[100] 
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  _slides[_selectedSlideIndex]["questionType"] == 'Multiple Choice' 
                                      ? 'Choix Multiple' 
                                      : 'Vrai ou Faux',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _slides[_selectedSlideIndex]["questionType"] == 'Multiple Choice' 
                                        ? Colors.blue[800] 
                                        : Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          ..._slides[_selectedSlideIndex]["questions"].asMap().entries.map((entry) {
                            int questionIndex = entry.key;
                            Map<String, dynamic> question = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Card(
                                color: _slides[_selectedSlideIndex]["backgroundImage"] != null && 
                                       _slides[_selectedSlideIndex]["backgroundImage"].isNotEmpty
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.pink[50],
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10),
                                      TextField(
                                        onChanged: (value) {
                                          setState(() {
                                            question["question"] = value;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: "Énoncé de la question",
                                          border: OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.8),
                                        ),
                                        controller: TextEditingController(text: question["question"])..selection = TextSelection.fromPosition(TextPosition(offset: question["question"].length)),
                                      ),
                                      SizedBox(height: 10),
                                      // Options de réponse en fonction du type de question
                                      _slides[_selectedSlideIndex]["questionType"] == 'Multiple Choice'
                                        ? Column(
                                            children: [
                                              for (int i = 1; i <= 4; i++)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 8.0),
                                                  child: Row(
                                                    children: [
                                                      // Add radio button for selecting the correct answer
                                                      Radio<String>(
                                                        value: 'option$i',
                                                        groupValue: question["correctAnswer"] ?? '',
                                                        onChanged: (value) {
                                                          setState(() {
                                                            question["correctAnswer"] = value;
                                                          });
                                                        },
                                                      ),
                                                      // Option text field
                                                      Expanded(
                                                        child: TextField(
                                                          onChanged: (value) {
                                                            setState(() {
                                                              question["option$i"] = value;
                                                            });
                                                          },
                                                          decoration: InputDecoration(
                                                            labelText: "Option $i",
                                                            border: OutlineInputBorder(),
                                                            filled: true,
                                                            fillColor: Colors.white.withOpacity(0.8),
                                                          ),
                                                          controller: TextEditingController(text: question["option$i"])
                                                            ..selection = TextSelection.fromPosition(TextPosition(offset: question["option$i"]?.length ?? 0)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              // Option Vrai
                                              Container(
                                                margin: EdgeInsets.only(bottom: 8.0),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey),
                                                  borderRadius: BorderRadius.circular(4),
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                                child: ListTile(
                                                  leading: Radio<String>(
                                                    value: 'Vrai',
                                                    groupValue: question["correctAnswer"] ?? '',
                                                    onChanged: (value) {
                                                      setState(() {
                                                        question["correctAnswer"] = value;
                                                      });
                                                    },
                                                  ),
                                                  title: Text("Vrai", style: TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              // Option Faux
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey),
                                                  borderRadius: BorderRadius.circular(4),
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                                child: ListTile(
                                                  leading: Radio<String>(
                                                    value: 'Faux',
                                                    groupValue: question["correctAnswer"] ?? '',
                                                    onChanged: (value) {
                                                      setState(() {
                                                        question["correctAnswer"] = value;
                                                      });
                                                    },
                                                  ),
                                                  title: Text("Faux", style: TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  : Center(
                      child: Text(
                        "Aucun slide sélectionné. Créez un nouveau slide ou sélectionnez un existant.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ),
          // Partie droite (Temps et Points ou Thèmes)
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
                ? // Afficher le panneau des thèmes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thèmes disponibles",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Sélectionnez un arrière-plan pour votre slide:",
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
                          itemCount: _backgroundImages.length + 1, // +1 pour l'option "Pas de thème"
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // Option pour enlever le thème
                              return GestureDetector(
                                onTap: () => _applyThemeToCurrentSlide(''),
                                child: Card(
                                  color: Colors.white,
                                  elevation: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.block, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text("Pas de thème", textAlign: TextAlign.center),
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
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          image: DecorationImage(
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
                        "Note: L'image sera appliquée uniquement au slide sélectionné.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  )
                : // Afficher les réglages du slide (temps et points)
                  _selectedSlideIndex >= 0 && _selectedSlideIndex < _slides.length
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Réglages du Slide ${_selectedSlideIndex + 1}",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),

                          SizedBox(height: 20),
                          // Affichage du type de question dans les réglages
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Type de question",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        _slides[_selectedSlideIndex]["questionType"] == 'Multiple Choice'
                                            ? Icons.format_list_numbered
                                            : Icons.check_circle_outline,
                                        color: _slides[_selectedSlideIndex]["questionType"] == 'Multiple Choice'
                                            ? Colors.blue
                                            : Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _slides[_selectedSlideIndex]["questionType"] == 'Multiple Choice'
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
                          // Réglage du temps pour le slide sélectionné
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Temps par question",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                            "${_slides[_selectedSlideIndex]["time"]} secondes",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          // Logique pour éditer le temps
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              int? tempValue = _slides[_selectedSlideIndex]["time"];
                                              return AlertDialog(
                                                title: Text("Modifier le temps"),
                                                content: TextField(
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: "Entrez le temps en secondes",
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  controller: TextEditingController(text: tempValue.toString()),
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
                                                          _slides[_selectedSlideIndex]["time"] = tempValue!;
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
                          // Réglage des points pour le slide sélectionné
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Points par question",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                            "${_slides[_selectedSlideIndex]["points"]} points",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          // Logique pour éditer les points
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              int? pointsValue = _slides[_selectedSlideIndex]["points"];
                                              return AlertDialog(
                                                title: Text("Modifier les points"),
                                                content: TextField(
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: "Entrez le nombre de points",
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  controller: TextEditingController(text: pointsValue.toString()),
                                                  onChanged: (value) {
                                                    pointsValue = int.tryParse(value);
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
                                                        if (pointsValue != null) {
                                                          _slides[_selectedSlideIndex]["points"] = pointsValue!;
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
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),  ),
        ],
      ),
    );

  }
    }
    