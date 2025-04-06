import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle de question
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final int timeInSeconds;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.timeInSeconds,
  });
}

class QuizPresentationPage extends StatefulWidget {
  final String quizId;
  final String quizName;

  const QuizPresentationPage({
    Key? key,
    required this.quizId,
    required this.quizName,
  }) : super(key: key);

  @override
  _QuizPresentationPageState createState() => _QuizPresentationPageState();
}

class _QuizPresentationPageState extends State<QuizPresentationPage> {
  int currentQuestionIndex = 0;
  late Timer timer;
  int remainingSeconds = 0;
  bool isQuizFinished = false;
  bool isLoading = true;
  String errorMessage = '';
  
  // Variables pour gérer les réponses de l'utilisateur
  int? selectedOptionIndex;
  List<int?> userAnswers = [];
  int correctAnswers = 0;

  // Liste de questions
  List<QuizQuestion> questions = [];

  @override
  void initState() {
    super.initState();
    
    // Charger les questions du quiz depuis Firestore
    loadQuestionsFromFirestore();
  }

  // Charger les questions du quiz depuis Firestore
  Future<void> loadQuestionsFromFirestore() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Récupérer les données du quiz depuis Firestore
      DocumentSnapshot quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (!quizDoc.exists) {
        setState(() {
          isLoading = false;
          errorMessage = 'Quiz introuvable';
        });
        return;
      }

      Map<String, dynamic> quizData = quizDoc.data() as Map<String, dynamic>;
      
      // Récupérer les slides du quiz
      List<dynamic> slides = quizData['slides'] ?? [];
      
      List<QuizQuestion> loadedQuestions = [];
      
      // Parcourir chaque slide pour extraire les questions
      for (var slide in slides) {
        // Extraire les informations de la question principale du slide
        if (slide['questions'] != null && slide['questions'].isNotEmpty) {
          var questionData = slide['questions'][0]; // On prend la première question du slide
          
          // S'assurer que la question n'est pas vide
          if (questionData['question'] != null && questionData['question'].toString().trim().isNotEmpty) {
            List<String> options = [];
            int correctIndex = 0;
            
            // Déterminer le type de question et extraire les options
            if (slide['questionType'] == 'Multiple Choice') {
              // Pour les QCM, extraire les 4 options
              options.add(questionData['option1'] ?? '');
              options.add(questionData['option2'] ?? '');
              options.add(questionData['option3'] ?? '');
              options.add(questionData['option4'] ?? '');
              
              // Déterminer la réponse correcte (à adapter selon votre stockage)
              // Ici on suppose que vous stockez la réponse correcte comme texte
              String correctAnswer = questionData['correctAnswer'] ?? '';
              for (int i = 0; i < options.length; i++) {
                if (options[i] == correctAnswer) {
                  correctIndex = i;
                  break;
                }
              }
            } else if (slide['questionType'] == 'True/False') {
              // Pour les questions Vrai/Faux
              options.add('Vrai');
              options.add('Faux');
              
              // La réponse correcte est soit "Vrai" soit "Faux"
              correctIndex = questionData['correctAnswer'] == 'Vrai' ? 0 : 1;
            }
            
            // Ajouter la question à la liste
            loadedQuestions.add(
              QuizQuestion(
                question: questionData['question'],
                options: options,
                correctOptionIndex: correctIndex,
                timeInSeconds: slide['time'] ?? 30,
              )
            );
          }
        }
      }
      
      setState(() {
        questions = loadedQuestions;
        isLoading = false;
        
        // Initialiser la liste des réponses utilisateur
        userAnswers = List.filled(loadedQuestions.length, null);
        
        if (questions.isEmpty) {
          errorMessage = 'Aucune question trouvée dans ce quiz';
        } else {
          // Démarrer le timer pour la première question
          startQuestionTimer();
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors du chargement du quiz: $e';
      });
      print('Erreur lors du chargement du quiz: $e');
    }
  }

  // Démarrer le chronomètre pour la question actuelle
  void startQuestionTimer() {
    if (currentQuestionIndex >= questions.length) {
      setState(() {
        isQuizFinished = true;
      });
      return;
    }

    // Réinitialiser la sélection pour la nouvelle question
    selectedOptionIndex = userAnswers[currentQuestionIndex];
    
    remainingSeconds = questions[currentQuestionIndex].timeInSeconds;
    
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          // Passer à la question suivante quand le temps est écoulé
          moveToNextQuestion();
        }
      });
    });
  }

  // Passer à la question suivante
  void moveToNextQuestion() {
    timer.cancel();
    
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      startQuestionTimer();
    } else {
      // Calculer le score final
      calculateFinalScore();
    }
  }

  // Calculer le score final
  void calculateFinalScore() {
    correctAnswers = 0;
    
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i].correctOptionIndex) {
        correctAnswers++;
      }
    }
    
    setState(() {
      isQuizFinished = true;
    });
  }

  // Méthode pour choisir une réponse
  void selectOption(int index) {
    setState(() {
      selectedOptionIndex = index;
      userAnswers[currentQuestionIndex] = index;
    });
  }

  @override
  void dispose() {
    if (!isLoading && questions.isNotEmpty) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizName),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Quitter la présentation'),
                  content: Text('Êtes-vous sûr de vouloir terminer la présentation du quiz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Fermer la boîte de dialogue
                        Navigator.pop(context); // Revenir à la page précédente
                      },
                      child: Text('Quitter'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading 
          ? _buildLoadingView()
          : errorMessage.isNotEmpty 
              ? _buildErrorView() 
              : isQuizFinished
                  ? _buildQuizFinishedView()
                  : _buildQuestionView(),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Chargement du quiz...',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          SizedBox(height: 20),
          Text(
            errorMessage,
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final question = questions[currentQuestionIndex];
    
    return Column(
      children: [
        // Barre de progression et chronomètre
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestionIndex + 1}/${questions.length}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(Icons.timer, color: remainingSeconds < 5 ? Colors.red : Colors.blue),
                  SizedBox(width: 5),
                  Text(
                    '${remainingSeconds}s',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: remainingSeconds < 5 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Barre de progression visuelle
        LinearProgressIndicator(
          value: remainingSeconds / question.timeInSeconds,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            remainingSeconds < 5 ? Colors.red : Colors.blue,
          ),
        ),
        
        // Contenu de la question
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    question.question,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                
                // Options sélectionnables
                ...List.generate(
                  question.options.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: InkWell(
                      onTap: () => selectOption(index),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          color: selectedOptionIndex == index 
                              ? Colors.blue.shade200 
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedOptionIndex == index 
                                ? Colors.blue 
                                : Colors.grey.shade300,
                            width: selectedOptionIndex == index ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedOptionIndex == index 
                                    ? Colors.blue 
                                    : Colors.grey.shade300,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: selectedOptionIndex == index 
                                        ? Colors.white 
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: selectedOptionIndex == index 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Boutons de navigation
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: currentQuestionIndex > 0
                    ? () {
                        timer.cancel();
                        setState(() {
                          currentQuestionIndex--;
                        });
                        startQuestionTimer();
                      }
                    : null,
                icon: Icon(Icons.arrow_back),
                label: Text('Précédent'),
              ),
              ElevatedButton(
                onPressed: selectedOptionIndex != null 
                    ? () => moveToNextQuestion() 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text(
                  'Valider',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  moveToNextQuestion();
                },
                icon: Icon(Icons.arrow_forward),
                label: Text('Passer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizFinishedView() {
    double scorePercentage = (correctAnswers / questions.length) * 100;
    bool isSuccess = scorePercentage >= 70; // Considérer 70% comme seuil de réussite
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSuccess ? Icons.emoji_events : Icons.watch_later_outlined,
            size: 100,
            color: isSuccess ? Colors.amber : Colors.orange,
          ),
          SizedBox(height: 20),
          Text(
            isSuccess ? 'Félicitations!' : 'Quiz terminé',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.green.shade800 : Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Votre score',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSuccess ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Text(
              '$correctAnswers / ${questions.length} (${scorePercentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
          SizedBox(height: 30),
          Text(
            isSuccess 
                ? 'Bravo, vous avez réussi le quiz!' 
                : 'Continuez à vous entraîner pour améliorer votre score!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Recharger le quiz pour recommencer
                  setState(() {
                    isQuizFinished = false;
                    currentQuestionIndex = 0;
                    selectedOptionIndex = null;
                    userAnswers = List.filled(questions.length, null);
                  });
                  startQuestionTimer();
                },
                icon: Icon(Icons.refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                label: Text('Recommencer'),
              ),
              SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                label: Text('Accueil'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}