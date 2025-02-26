import 'package:flutter/material.dart';

class JoinQuizPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join a Quiz')),
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(labelText: 'Enter Quiz Code'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add functionality to join the quiz
              },
              child: Text('Join Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
