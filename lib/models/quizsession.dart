import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/participant.dart';

class QuizSession {
  String id;
  String quizId;
  String activeQuestionId;
  QuestionState state;
  List<Participant> participants;
  DateTime createdAt;

  QuizSession({
    required this.id,
    required this.quizId,
    required this.activeQuestionId,
    required this.state,
    required this.participants,
    required this.createdAt,
  });

  factory QuizSession.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return QuizSession(
      id: doc.id,
      quizId: data['quizId'],
      activeQuestionId: data['activeQuestionId'],
      state: QuestionState.values[data['state']],
      participants: (data['participants'] as List).map((p) => Participant.fromMap(p)).toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'activeQuestionId': activeQuestionId,
      'state': state.index,
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

enum QuestionState {
  waitingForParticipants,
  answeringQuestion,
  displayingResult
}

