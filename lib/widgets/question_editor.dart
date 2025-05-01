import 'package:flutter/material.dart';
import '../../models/question.dart';

class QuestionEditor extends StatelessWidget {
  final Question question;
  final Function(String) onQuestionTextChanged;
  final Function(String) onCorrectOptionChanged;
  final Function(int, String) onOptionTextChanged;
  final String selectedBackgroundImage;

  const QuestionEditor({
    Key? key,
    required this.question,
    required this.onQuestionTextChanged,
    required this.onCorrectOptionChanged,
    required this.onOptionTextChanged,
    required this.selectedBackgroundImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (question.questionType == 'Ranking') {
      return Center(
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.leaderboard,
                size: 64,
                color: Colors.blue,
              ),
              SizedBox(height: 20),
              Text(
                "Slide de Classement",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Ce slide affichera automatiquement le classement en temps réel\ndes participants pendant le quiz.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.yellow[700],
                        child: Text("1", style: TextStyle(color: Colors.white)),
                      ),
                      title: Text("Participant 1"),
                      trailing: Text("1000 pts"),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[400],
                        child: Text("2", style: TextStyle(color: Colors.white)),
                      ),
                      title: Text("Participant 2"),
                      trailing: Text("800 pts"),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange[700],
                        child: Text("3", style: TextStyle(color: Colors.white)),
                      ),
                      title: Text("Participant 3"),
                      trailing: Text("600 pts"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Row(
            children: [
              Text(
                "Question",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: question.options.length > 2
                      ? Colors.blue[100] 
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  question.options.length > 2
                      ? 'Choix Multiple' 
                      : 'Vrai ou Faux',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: question.options.length > 2
                        ? Colors.blue[800] 
                        : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Card(
            color: selectedBackgroundImage.isNotEmpty
                ? Colors.white.withOpacity(0.7)
                : Colors.pink[50],
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  TextField(
                    onChanged: onQuestionTextChanged,
                    decoration: InputDecoration(
                      labelText: "Énoncé de la question",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    controller: TextEditingController(text: question.text)
                      ..selection = TextSelection.fromPosition(TextPosition(offset: question.text.length)),
                  ),
                  SizedBox(height: 10),
                  question.options.length > 2
                    ? Column(
                        children: [
                          for (int i = 0; i < question.options.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: question.options[i].id,
                                    groupValue: question.correctOptionId,
                                    onChanged: (value) => onCorrectOptionChanged(value!),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) => onOptionTextChanged(i, value),
                                      decoration: InputDecoration(
                                        labelText: "Option ${i + 1}",
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.8),
                                      ),
                                      controller: TextEditingController(text: question.options[i].text)
                                        ..selection = TextSelection.fromPosition(TextPosition(offset: question.options[i].text.length)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 8.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white.withOpacity(0.8),
                            ),
                            child: ListTile(
                              leading: Radio<String>(
                                value: question.options[0].id,
                                groupValue: question.correctOptionId,
                                onChanged: (value) => onCorrectOptionChanged(value!),
                              ),
                              title: Text("Vrai", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white.withOpacity(0.8),
                            ),
                            child: ListTile(
                              leading: Radio<String>(
                                value: question.options[1].id,
                                groupValue: question.correctOptionId,
                                onChanged: (value) => onCorrectOptionChanged(value!),
                              ),
                              title: Text("Faux", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 