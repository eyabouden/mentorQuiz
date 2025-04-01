import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'create_quiz_page.dart';
import 'join_quiz_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentor Quiz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/dashboard': (context) => DashboardPage(),
        '/create-quiz': (context) => CreateQuizPage(),
        '/join-quiz': (context) => JoinQuizPage(),
      },
    );
  }
}