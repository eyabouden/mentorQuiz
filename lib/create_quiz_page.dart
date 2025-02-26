import 'package:flutter/material.dart';

class CreateQuizPage extends StatefulWidget {
  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final TextEditingController _quizTitleController = TextEditingController();
  final List<Map<String, String>> _questions = [];

  void _addQuestion() {
    setState(() {
      _questions.add({"question": "", "option1": "", "option2": "", "option3": "", "option4": ""});
    });
  }

  void _saveQuiz() {
    // Logic to save the quiz
    print("Quiz saved: ${_quizTitleController.text}");
    print("Questions: $_questions");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create a Quiz"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title input
              TextField(
                controller: _quizTitleController,
                decoration: InputDecoration(
                  labelText: "Enter Quiz Title",
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),

              // Questions section
              Text(
                "Questions",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,  // Ensures ListView takes only the space it needs
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            onChanged: (value) {
                              _questions[index]["question"] = value;
                            },
                            decoration: InputDecoration(
                              labelText: "Question ${index + 1}",
                              border: OutlineInputBorder(),
                            ),
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 10),
                          for (int i = 1; i <= 4; i++)
                            TextField(
                              onChanged: (value) {
                                _questions[index]["option$i"] = value;
                              },
                              decoration: InputDecoration(
                                labelText: "Option $i",
                                border: OutlineInputBorder(),
                              ),
                              style: TextStyle(fontSize: 18),
                            ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Add question button
              ElevatedButton(
                onPressed: _addQuestion,
                child: Text("Add Question"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Save quiz button
              ElevatedButton(
                onPressed: _saveQuiz,
                child: Text("Save Quiz"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
