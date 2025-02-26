import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createQuiz(String title) async {
    try {
      await _firestore.collection('quizzes').add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating quiz: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getQuizzes() async {
    try {
      final snapshot = await _firestore.collection('quizzes').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching quizzes: $e");
      return [];
    }
  }
}
