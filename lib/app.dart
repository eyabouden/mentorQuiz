import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:firebase_core/firebase_core.dart';

>>>>>>> bf47149a1fcca063954008df2d1cb7cded7cae0f
import 'home_page.dart';
import 'create_quiz_page.dart';
import 'join_quiz_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/create-quiz': (context) => CreateQuizPage(),
        '/join-quiz': (context) => JoinQuizPage(),
      },

      
    );
  }
}
