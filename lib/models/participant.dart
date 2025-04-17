import 'package:cloud_firestore/cloud_firestore.dart';

class Participant {
  String id;
  String username;
  String iconUrl;
  int totalScore;

  Participant({
    required this.id,
    required this.username,
    required this.iconUrl,
    required this.totalScore,
  });

  factory Participant.fromMap(Map<String, dynamic> data) {
    return Participant(
      id: data['id'],
      username: data['username'],
      iconUrl: data['iconUrl'],
      totalScore: data['totalScore'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'iconUrl': iconUrl,
      'totalScore': totalScore,
    };
  }
}