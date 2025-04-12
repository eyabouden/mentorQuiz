import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_edit_page.dart';
import 'create_quiz_page.dart'; // Import the create quiz page

class MyQuizzesPage extends StatefulWidget {
  @override
  _MyQuizzesPageState createState() => _MyQuizzesPageState();
}

class _MyQuizzesPageState extends State<MyQuizzesPage> {
  List<Map<String, dynamic>> _quizzes = [];

  void _fetchQuizzes() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        var quizData = await FirebaseFirestore.instance
            .collection('quizzes')
            .where('userId', isEqualTo: userId)
            .get();

        setState(() {
          _quizzes = quizData.docs.map((doc) {
            var data = doc.data();
            data['id'] = doc.id; // Store document ID
            data['createdAt'] = data['createdAt']?.toDate();
            return data;
          }).toList();
        });
      } catch (e) {
        print("Error fetching quizzes: $e");
      }
    } else {
      print('No user is logged in');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Quizzes"), backgroundColor: Colors.blue),
      body: _quizzes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                var quiz = _quizzes[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(quiz['title'] ?? 'Untitled Quiz'),
                    subtitle: Text("Created on: ${quiz['createdAt'] ?? 'N/A'}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizEditPage(quizId: quiz['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateQuizPage()),
          ).then((_) {
            // Refresh quiz list when returning from create page
            _fetchQuizzes();
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        tooltip: 'Create New Quiz',
      ),
    );
  }
}