import 'package:flutter/material.dart';

class CreateQuizPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create a Quiz')),
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(labelText: 'Quiz Title'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add functionality to create the quiz
              },
              child: Text('Create Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
