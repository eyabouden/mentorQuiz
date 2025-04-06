import 'package:flutter/material.dart';

class JoinQuizPage extends StatefulWidget {
  @override
  _JoinQuizPageState createState() => _JoinQuizPageState();
}

class _JoinQuizPageState extends State<JoinQuizPage> {
  final TextEditingController _quizCodeController = TextEditingController();

  void _joinQuiz() {
    String code = _quizCodeController.text;
    if (code.isNotEmpty) {
      // Logic to join the quiz with the entered code
      print("Joining quiz with code: $code");
      // You can add Firebase or other logic here to validate the code and join the quiz
    } else {
      print("Please enter a valid quiz code");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Join a Quiz"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Enter Code to Join a Live Quiz",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Quiz code input
            TextField(
              controller: _quizCodeController,
              decoration: InputDecoration(
                labelText: "Enter Quiz Code",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),

            // Join Quiz Button
            ElevatedButton(
              onPressed: _joinQuiz,
              child: Text("Join Quiz"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15), backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}