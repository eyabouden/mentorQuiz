import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizEditPage extends StatefulWidget {
  final String quizId;

  QuizEditPage({required this.quizId});

  @override
  _QuizEditPageState createState() => _QuizEditPageState();
}

class _QuizEditPageState extends State<QuizEditPage> {
  final TextEditingController _quizTitleController = TextEditingController();
  List<Map<String, dynamic>> _slides = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  void _fetchQuizData() async {
    var quizDoc = await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).get();
    if (quizDoc.exists) {
      var data = quizDoc.data()!;
      setState(() {
        _quizTitleController.text = data['title'];
        _slides = List<Map<String, dynamic>>.from(data['slides']);
      });
    }
  }

  void _saveUpdatedQuiz() async {
    await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).update({
      'title': _quizTitleController.text,
      'slides': _slides,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Quiz updated successfully!")));
  }

  void _addSlide() {
    setState(() {
      _slides.add({"title": "", "questionType": "Multiple Choice", "questions": []});
    });
  }

  void _addQuestionToSlide(int slideIndex) {
    setState(() {
      _slides[slideIndex]["questions"].add({
        "question": "",
        "option1": "",
        "option2": "",
        "option3": "",
        "option4": "",
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Quiz"), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _quizTitleController,
              decoration: InputDecoration(labelText: "Quiz Title", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            Text("Quiz Slides", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _slides.length,
              itemBuilder: (context, slideIndex) {
                var slide = _slides[slideIndex];
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (value) => _slides[slideIndex]["title"] = value,
                          decoration: InputDecoration(labelText: "Slide Title", border: OutlineInputBorder()),
                        ),
                        SizedBox(height: 10),
                        DropdownButton<String>(
                          value: slide["questionType"],
                          onChanged: (value) => setState(() => _slides[slideIndex]["questionType"] = value!),
                          items: ['Multiple Choice', 'True/False', 'Text Response']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                        ),
                        SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: slide["questions"].length,
                          itemBuilder: (context, questionIndex) {
                            var question = slide["questions"][questionIndex];
                            return Column(
                              children: [
                                TextField(
                                  onChanged: (value) => _slides[slideIndex]["questions"][questionIndex]["question"] = value,
                                  decoration: InputDecoration(labelText: "Question", border: OutlineInputBorder()),
                                ),
                                if (slide["questionType"] == 'Multiple Choice')
                                  for (int i = 1; i <= 4; i++)
                                    TextField(
                                      onChanged: (value) => _slides[slideIndex]["questions"][questionIndex]["option$i"] = value,
                                      decoration: InputDecoration(labelText: "Option $i", border: OutlineInputBorder()),
                                    ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _addQuestionToSlide(slideIndex),
                          child: Text("Add Question"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _addSlide, child: Text("Add Slide")),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _saveUpdatedQuiz, child: Text("Save Changes"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
          ],
        ),
      ),
    );
  }
}
