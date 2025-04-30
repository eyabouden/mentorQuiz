import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentor_quiz/models/participant.dart';

class QuizSession {
  String id;
  String quizId;
  String activeQuestionId;
  QuestionState state;
  List<Participant> participants;
  DateTime createdAt;
  DateTime? endTime;
  bool isFinished;

  QuizSession({
    required this.id,
    required this.quizId,
    required this.activeQuestionId,
    required this.state,
    required this.participants,
    required this.createdAt,
    this.endTime,
    this.isFinished = false,
  });

  factory QuizSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return QuizSession(
      id: doc.id,
      quizId: data['quizId'] ?? '',
      activeQuestionId: data['activeQuestionId'] ?? '',
      state: QuestionState.values[data['state'] ?? 0],
      participants: ((data['participants'] as List?) ?? [])
          .map((p) => Participant.fromMap(p as Map<String, dynamic>))
          .toList(),
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now()).toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      isFinished: data['isFinished'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'activeQuestionId': activeQuestionId,
      'state': state.index,
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      'isFinished': isFinished,
    };
  }
  
  // Get participant by ID
  Participant? getParticipantById(String participantId) {
    for (var participant in participants) {
      if (participant.id == participantId) {
        return participant;
      }
    }
    return null;
  }

  // Add a new participant
  void addParticipant(Participant participant) {
    // Check if participant with same ID already exists
    if (getParticipantById(participant.id) == null) {
      participants.add(participant);
    }
  }

  // Update participant scores
  void updateParticipantScore(String participantId, int additionalScore) {
    final participant = getParticipantById(participantId);
    if (participant != null) {
      participant.totalScore += additionalScore;
    }
  }
}

enum QuestionState {
  waitingForParticipants,
  answeringQuestion,
  displayingResult
}