import 'package:flutter/material.dart';
import '../../models/question.dart';

class QuestionList extends StatelessWidget {
  final List<Question> questions;
  final int selectedQuestionIndex;
  final Function(int) onQuestionSelected;
  final Function(int) onQuestionDeleted;
  final Function() onAddQuestion;
  final Function(int, int) onQuestionReordered;

  const QuestionList({
    Key? key,
    required this.questions,
    required this.selectedQuestionIndex,
    required this.onQuestionSelected,
    required this.onQuestionDeleted,
    required this.onAddQuestion,
    required this.onQuestionReordered,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Liste des questions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Expanded(
          child: ReorderableListView.builder(
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              onQuestionReordered(oldIndex, newIndex);
            },
            itemCount: questions.length,
            itemBuilder: (context, index) {
              Question question = questions[index];
              String questionType = question.options.length > 2 ? 'Multiple Choice' : 'True/False';
              
              return Card(
                key: ValueKey(question.id),
                color: selectedQuestionIndex == index ? Colors.blue[100] : Colors.white,
                margin: EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text("${index + 1}", style: TextStyle(color: Colors.white)),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text("Question ${index + 1}"),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: questionType == 'Multiple Choice' 
                              ? Colors.blue[100] 
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          questionType == 'Multiple Choice' ? 'QCM' : 'V/F',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: questionType == 'Multiple Choice' 
                                ? Colors.blue[800] 
                                : Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drag_handle, color: Colors.grey),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onQuestionDeleted(index),
                      ),
                    ],
                  ),
                  onTap: () => onQuestionSelected(index),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onAddQuestion,
          icon: Icon(Icons.add),
          label: Text("Ajouter une Question"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }
} 