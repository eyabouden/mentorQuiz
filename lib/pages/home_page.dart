import 'package:flutter/material.dart';
//import 'create_quiz_page.dart';
//import 'join_quiz_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome to Quiz App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-quiz');
              },
              child: Text('Create Quiz'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/join-quiz');
              },
              child: Text('Join Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
