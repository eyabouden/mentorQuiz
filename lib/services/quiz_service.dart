import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart'; // Importer AuthService

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

   Future<void> saveQuiz(String quizTitle, List<Map<String, dynamic>> slides, String userId) async {
    try {
      // Add the quiz data to Firestore
      DocumentReference docRef = await _db.collection('quizzes').add({
        'title': quizTitle,
        'slides': slides, // The slides of the quiz, with dynamic types
        'userId': userId, // Associate the quiz with the logged-in user
        'createdAt': FieldValue.serverTimestamp(), // Automatically set the creation time
      });

      // Optionally, log the document ID for debugging
      print('Quiz saved with ID: ${docRef.id}');
    } catch (e) {
      // Handle errors
      print('Error saving the quiz: $e');
    }
  }


  Future<List<Map<String, dynamic>>> fetchQuizzes() async {
    try {
      String? userId = AuthService().currentUserId;
      if (userId == null) return [];

      QuerySnapshot querySnapshot =
          await _db.collection('quizzes').where('userId', isEqualTo: userId).get();
      
      return querySnapshot.docs.map((doc) => {
            'id': doc.id,
            'title': doc['title'],
            'questions': List<Map<String, String>>.from(doc['questions']),
          }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des quiz: $e');
      return [];
    }
  }
}
