import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizCompetitionPage extends StatefulWidget {
  final String quizId;
  final String userId;
  final String nickname;
  final String avatar;

  QuizCompetitionPage({
    required this.quizId,
    required this.userId,
    required this.nickname,
    required this.avatar,
  });

  @override
  _QuizCompetitionPageState createState() => _QuizCompetitionPageState();
}

class _QuizCompetitionPageState extends State<QuizCompetitionPage> {
  Map<String, dynamic>? _quizData;
  int _currentSlideIndex = 0;
  Map<String, dynamic>? _currentSlide;
  String? _selectedAnswer;
  List<Map<String, dynamic>> _participants = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
    _registerParticipant();
  }

  void _fetchQuizData() async {
    var quizDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .get();

    setState(() {
      _quizData = quizDoc.data();
      _currentSlide = _quizData?['slides'][_currentSlideIndex];
    });
  }

  void _registerParticipant() async {
    await FirebaseFirestore.instance
        .collection('quiz_sessions')
        .doc(widget.quizId)
        .collection('participants')
        .doc(widget.userId)
        .set({
      'nickname': widget.nickname,
      'avatar': widget.avatar,
      'score': 0,
    });
  }

  void _nextSlide() {
    setState(() {
      if (_currentSlideIndex < _quizData?['slides'].length - 1) {
        _currentSlideIndex++;
        _currentSlide = _quizData?['slides'][_currentSlideIndex];
        _selectedAnswer = null;
      }
    });
  }

  void _submitAnswer() async {
    // Here you would implement the logic to check the answer and update the score
    await FirebaseFirestore.instance
        .collection('quiz_sessions')
        .doc(widget.quizId)
        .collection('participants')
        .doc(widget.userId)
        .update({
      'score': FieldValue.increment(1), // Simple scoring mechanism
    });

    _nextSlide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quizData?['title'] ?? 'Quiz'),
      ),
      body: _currentSlide == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _currentSlide?['title'] ?? '',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    _currentSlide?['questions'][0]['question'] ?? '',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  if (_currentSlide?['questionType'] == 'Multiple Choice')
                    Column(
                      children: [
                        for (int i = 1; i <= 4; i++)
                          RadioListTile(
                            title: Text(_currentSlide?['questions'][0]['option$i'] ?? ''),
                            value: _currentSlide?['questions'][0]['option$i'],
                            groupValue: _selectedAnswer,
                            onChanged: (value) {
                              setState(() {
                                _selectedAnswer = value;
                              });
                            },
                          ),
                      ],
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedAnswer != null ? _submitAnswer : null,
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
    );
  }
}