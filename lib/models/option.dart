import 'package:cloud_firestore/cloud_firestore.dart';

class Option {
  String id;
  String text;

  Option({required this.id, required this.text});

  factory Option.fromMap(Map<String, dynamic> data) {
    return Option(
      id: data['id'],
      text: data['text'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
    };
  }
}