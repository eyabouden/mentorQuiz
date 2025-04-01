import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_quiz_page.dart';
import 'my_quizzes_page.dart';
import 'join_quiz_page.dart';
import 'services/auth_service.dart';

class DashboardPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateQuizPage()),
                );
              },
              icon: Icon(Icons.create),
              label: Text('Create New Quiz'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyQuizzesPage()),
                );
              },
              icon: Icon(Icons.list),
              label: Text('My Quizzes'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JoinQuizPage()),
                );
              },
              icon: Icon(Icons.join_inner),
              label: Text('Join Quiz'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}