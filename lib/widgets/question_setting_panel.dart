import 'package:flutter/material.dart';
import '../../models/question.dart';

class QuestionSettingPanel extends StatelessWidget {
  final Question question;
  final int questionIndex;
  final Function(int) onTimeChanged;
  final Function(int) onPointsChanged;

  const QuestionSettingPanel({
    Key? key,
    required this.question,
    required this.questionIndex,
    required this.onTimeChanged,
    required this.onPointsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Réglages de la Question ${questionIndex + 1}",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Card(
          color: Colors.white,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Type de question",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      question.options.length > 2
                          ? Icons.format_list_numbered
                          : Icons.check_circle_outline,
                      color: question.options.length > 2
                          ? Colors.blue
                          : Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text(
                      question.options.length > 2
                          ? "Choix Multiple"
                          : "Vrai ou Faux",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Card(
          color: Colors.white,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Temps par question",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          "${question.timeAllowed} secondes",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showTimeEditDialog(context),
                      icon: Icon(Icons.edit, size: 16),
                      tooltip: "Modifier le temps",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Card(
          color: Colors.white,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Points par question",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          "10 points",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showPointsEditDialog(context),
                      icon: Icon(Icons.edit, size: 16),
                      tooltip: "Modifier les points",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTimeEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int? tempValue = question.timeAllowed;
        return AlertDialog(
          title: Text("Modifier le temps"),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Entrez le temps en secondes",
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: tempValue.toString()),
            onChanged: (value) {
              tempValue = int.tryParse(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempValue != null) {
                  onTimeChanged(tempValue!);
                }
                Navigator.of(context).pop();
              },
              child: Text("Enregistrer"),
            ),
          ],
        );
      },
    );
  }

  void _showPointsEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int? pointsValue = 10;
        return AlertDialog(
          title: Text("Modifier les points"),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Entrez le nombre de points",
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: pointsValue.toString()),
            onChanged: (value) {
              pointsValue = int.tryParse(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (pointsValue != null) {
                  onPointsChanged(pointsValue!);
                }
                Navigator.of(context).pop();
              },
              child: Text("Enregistrer"),
            ),
          ],
        );
      },
    );
  }
} 