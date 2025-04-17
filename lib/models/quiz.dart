import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/question.dart';

class Quiz {
  final String id;
  final String title;
  final DateTime createdAt;
  String? participationCode;
  List<Question>? questions;
  DateTime? updatedAt;
  final String userId; // Ajout de l'userId

  Quiz({
    required this.id,
    required this.title,
    required this.createdAt,
    this.participationCode,
    this.questions,
    this.updatedAt,
    required this.userId, // Ajout de l'userId
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      participationCode: data['participationCode'],
      questions: data['questions'] != null
          ? (data['questions'] as List).map((q) => Question.fromMap(q)).toList()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      userId: data['userId'], // Récupération de userId
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'participationCode': participationCode,
      'questions': questions?.map((q) => q.toMap()).toList(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'userId': userId, // Sérialisation de userId
    };
  }
}