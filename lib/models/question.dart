import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/option.dart';

class Question {
  String id;
  String text;
  List<Option> options;
  String correctOptionId;
  int timeAllowed;
  int points;
  String? backgroundImage;
  String questionType;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionId,
    required this.timeAllowed,
    this.points = 100,
    this.backgroundImage,
    required this.questionType,
  });

  factory Question.fromMap(Map<String, dynamic> data) {
    return Question(
      id: data['id'],
      text: data['text'],
      options: (data['options'] as List)
          .map((a) => Option.fromMap(a as Map<String, dynamic>))
          .toList(),
      correctOptionId: data['correctOptionId'],
      timeAllowed: data['timeAllowed'],
      points: data['points'] ?? 100,
      backgroundImage: data['backgroundImage'],
      questionType: data['questionType'],
    );
  }

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': options.map((a) => a.toMap()).toList(),
      'correctOptionId': correctOptionId,
      'timeAllowed': timeAllowed,
      'points': points,
      'backgroundImage': backgroundImage,
      'questionType': questionType,
    };
  }
}
