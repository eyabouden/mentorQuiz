import 'package:flutter/material.dart';
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
