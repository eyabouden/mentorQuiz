import 'package:cloud_firestore/cloud_firestore.dart';

class Response {
  String id;
  String sessionId;
  String questionId;
  String participantId;
  String answerId;
  int score;
  DateTime submittedAt;
  bool isCorrect;  

  Response({
    required this.id,
    required this.sessionId,
    required this.questionId,
    required this.participantId,
    required this.answerId,
    required this.score,
    required this.submittedAt,
    required this.isCorrect, 
  });

  factory Response.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Response(
      id: doc.id,
      sessionId: data['sessionId'],
      questionId: data['questionId'],
      participantId: data['participantId'],
      answerId: data['answerId'],
      score: data['score'],
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      isCorrect: data['isCorrect'] ?? false, 
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'questionId': questionId,
      'participantId': participantId,
      'answerId': answerId,
      'score': score,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'isCorrect': isCorrect, 
    };
  }
}
