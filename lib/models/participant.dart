// participant.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Participant {
  final String id;
  final String username;
  final String avatar;
  final String avatarColor;
  final String avatarType;
  int totalScore;
  
  Participant({
    required this.id,
    required this.username,
    required this.avatar,
    required this.avatarColor,
    this.avatarType = 'emoji',
    this.totalScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'avatarColor': avatarColor,
      'avatarType': avatarType,
      'totalScore': totalScore,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      avatar: map['avatar'] ?? '😀',
      avatarColor: map['avatarColor'] ?? '#2196F3', // Default blue color
      avatarType: map['avatarType'] ?? 'emoji',
      totalScore: map['totalScore'] ?? 0,
    );
  }

  factory Participant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Participant.fromMap(data);
  }

  Participant copyWith({
    String? id,
    String? username,
    String? avatar,
    String? avatarColor,
    String? avatarType,
    int? totalScore,
  }) {
    return Participant(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarType: avatarType ?? this.avatarType,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}