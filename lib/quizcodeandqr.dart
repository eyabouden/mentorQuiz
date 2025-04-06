import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mentor_quiz/quiz_presentation_page.dart';

// Classe utilitaire pour la génération du code d'accès
class QuizCodeGenerator {
  // Génère un code aléatoire de 6 caractères (lettres majuscules et chiffres)
  static String generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
  
  // Génère l'URL ou le lien pour le quiz (à adapter selon votre système)
  static String generateQuizLink(String quizId, String accessCode) {
    // Remplacez cette URL par votre domaine réel ou format d'URL profonde
    return 'https://yourapp.com/quiz/$quizId?code=$accessCode';
  }
}

// Page qui affiche le code d'accès et le QR code
class QuizAccessPage extends StatelessWidget {
  final String quizName;
  final String quizId;
  final String accessCode;
  final String quizLink;

  QuizAccessPage({
    Key? key, 
    required this.quizName,
    required this.quizId,
  }) : 
    accessCode = QuizCodeGenerator.generateAccessCode(),
    quizLink = QuizCodeGenerator.generateQuizLink(quizId, QuizCodeGenerator.generateAccessCode()),
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Prêt'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              quizName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Code d\'accès:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        accessCode,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            QrImageView(
              data: quizLink,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Scannez le QR code ou utilisez le code ci-dessus\npour rejoindre le quiz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigation vers la page de présentation du quiz
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QuizPresentationPage(
                          quizId: quizId, // Use the instance variable directly
                          quizName: quizName, // Use the instance variable directly
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    'Démarrer le Quiz',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}