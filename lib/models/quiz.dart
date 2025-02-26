import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String title;
  final String id;
  final DateTime createdAt;

  Quiz({required this.title, required this.id, required this.createdAt});

  factory Quiz.fromFirestore(Map<String, dynamic> firestoreDoc) {
    return Quiz(
      title: firestoreDoc['title'],
      id: firestoreDoc['id'],
      createdAt: (firestoreDoc['createdAt'] as Timestamp).toDate(),  // Correctly cast Timestamp to DateTime
    );
  }
}
