import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyQuizzesPage extends StatefulWidget {
  @override
  _MyQuizzesPageState createState() => _MyQuizzesPageState();
}

class _MyQuizzesPageState extends State<MyQuizzesPage> {
  // List to hold the quizzes
  List<Map<String, dynamic>> _quizzes = [];

  // Fetch quizzes from Firestore
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
            // Convert Firestore document data into a Map
            var data = doc.data();
            // Ensure createdAt is a Firestore Timestamp
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
    _fetchQuizzes(); // Fetch quizzes when the page is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mes Quizs"),
        backgroundColor: Colors.blue,
      ),
      body: _quizzes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                var quiz = _quizzes[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(quiz['title'] ?? 'Untitled Quiz'),
                    subtitle: Text("Créé le: ${quiz['createdAt'] ?? 'N/A'}"),
                    onTap: () {
                      // Navigate to the quiz detail page (you can create one for this)
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => QuizDetailPage(quiz: quiz)));
                    },
                  ),
                );
              },
            ),
    );
  }
}
