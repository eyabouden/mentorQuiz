import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:mentor_quiz/my_quizzes_page.dart';

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
        '/my-quiz': (context) => MyQuizzesPage(),
        '/join-quiz': (context) => JoinQuizPage(),
      },

      
    );
  }
}