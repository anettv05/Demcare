import 'dart:math';
import 'package:flutter/material.dart';

class MemoryTestScreen extends StatefulWidget {
  final ValueChanged<String> onTestComplete;

  // onTestComplete is a callback that lets you pass the final result
  // (like "Latest Score: 85 / 100") back to the calling screen.
  const MemoryTestScreen({Key? key, required this.onTestComplete})
      : super(key: key);

  @override
  State<MemoryTestScreen> createState() => _MemoryTestScreenState();
}

class _MemoryTestScreenState extends State<MemoryTestScreen> {
  // Track the current question index.
  int _currentQuestionIndex = 0;

  // For scoring.
  double _totalScore = 0.0;

  // Store user answers for Q1 and Q2 (multiple choice).
  String? q1Answer;
  String? q2Answer;

  // For the first number question:
  late String randomDigits;
  final TextEditingController q4Controller = TextEditingController();

  // For Q5 & Q6 (Yes/No questions).
  String? q5Answer;
  String? q6Answer;

  // For the word questions, we use separate controllers for the answer slides.
  // Q7 & Q8: Expected word "test"
  final TextEditingController q7AnswerController = TextEditingController();
  // Q9 & Q10: Expected word "abc"
  final TextEditingController q8AnswerController = TextEditingController();
  // Q11 & Q12: Expected word "xyz"
  final TextEditingController q9AnswerController = TextEditingController();
  // Q13 & Q14: Expected word "hello"
  final TextEditingController q10AnswerController = TextEditingController();

  // NEW: For the additional number question.
  late String randomDigits2;
  final TextEditingController newNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    randomDigits = _generateRandomDigits(4);
    randomDigits2 = _generateRandomDigits(4); // new random 4-digit sequence
  }

  // Build the list of pages dynamically.
  // Pages order:
  // 1. Q1 (MCQ)
  // 2. Q2 (MCQ)
  // 3. Q3: Show first 4-digit sequence
  // 4. Q4: Input answer for first 4-digit sequence
  // 5. Q5: Yes/No question (misplacing objects)
  // 6. Q6: Yes/No question (forgetting speech)
  // 7. Q7: Show word "test"
  // 8. Q8: Input answer for "test"
  // 9. Q9: Show word "abc"
  // 10. Q10: Input answer for "abc"
  // 11. Q11: Show word "xyz"
  // 12. Q12: Input answer for "xyz"
  // 13. Q13: Show word "hello"
  // 14. Q14: Input answer for "hello"
  // 15. NEW: Show second 4-digit sequence
  // 16. NEW: Input answer for second 4-digit sequence
  // 17. Score Page.
  List<Widget> get _pages {
    return [
      _buildQ1Page(),           // Page 1: Q1 MCQ.
      _buildQ2Page(),           // Page 2: Q2 MCQ.
      _buildQ3ShowDigitsPage(), // Page 3: Show first 4-digit sequence.
      _buildQ3RecallDigitsPage(), // Page 4: Input answer for first 4-digit sequence.
      _buildQ4PageYesNo(),      // Page 5: Q5 Yes/No.
      _buildQ5PageYesNo(),      // Page 6: Q6 Yes/No.
      _buildQ6ShowWordPage(),   // Page 7: Show word "test".
      _buildQ6AnswerPage(),     // Page 8: Input answer for "test".
      _buildQ7ShowWordPage(),   // Page 9: Show word "abc".
      _buildQ7AnswerPage(),     // Page 10: Input answer for "abc".
      _buildQ8ShowWordPage(),   // Page 11: Show word "xyz".
      _buildQ8AnswerPage(),     // Page 12: Input answer for "xyz".
      _buildQ9ShowWordPage(),   // Page 13: Show word "hello".
      _buildQ9AnswerPage(),     // Page 14: Input answer for "hello".
      _buildq10NumberShowPage(),// Page 15: Show new 4-digit sequence.
      _buildq10NumberRecallPage(),// Page 16: Input answer for new 4-digit sequence.
      _buildScorePage(),        // Page 17: Final score.
    ];
  }

  // Generate a random digit string of given length.
  String _generateRandomDigits(int count) {
    final rand = Random();
    return List.generate(count, (_) => rand.nextInt(10).toString()).join();
  }

  // ---- PAGE BUILDERS ----

  // Q1: Multiple-choice for recent events.
  Widget _buildQ1Page() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q1) How accurately do you remember recent events?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        RadioListTile<String>(
          title: Text("Very Accurately"),
          value: "Very Accurately",
          groupValue: q1Answer,
          onChanged: (val) {
            setState(() {
              q1Answer = val;
            });
          },
        ),
        RadioListTile<String>(
          title: Text("Somewhat accurately"),
          value: "Somewhat accurately",
          groupValue: q1Answer,
          onChanged: (val) {
            setState(() {
              q1Answer = val;
            });
          },
        ),
        RadioListTile<String>(
          title: Text("Rarely accurately"),
          value: "Rarely accurately",
          groupValue: q1Answer,
          onChanged: (val) {
            setState(() {
              q1Answer = val;
            });
          },
        ),
        RadioListTile<String>(
          title: Text("Not at all"),
          value: "Not at all",
          groupValue: q1Answer,
          onChanged: (val) {
            setState(() {
              q1Answer = val;
            });
          },
        ),
      ],
    );
  }

  // Q2: Multiple-choice for phone numbers.
  Widget _buildQ2Page() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q2) How accurately do you remember phone numbers after hearing it once?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        RadioListTile<String>(
          title: Text("Very Accurately"),
          value: "Very Accurately",
          groupValue: q2Answer,
          onChanged: (val) {
            setState(() {
              q2Answer = val;
            });
          },
        ),
        RadioListTile<String>(
          title: Text("Somewhat accurately"),
          value: "Somewhat accurately",
          groupValue: q2Answer,
          onChanged: (val) {
            setState(() {
              q2Answer = val;
            });
          },
        ),
        RadioListTile<String>(
          title: Text("Rarely accurately"),
          value: "Rarely accurately",
          groupValue: q2Answer,
          onChanged: (val) {
            setState(() {
              q2Answer = val;
            });
          },
        ),
        RadioListTile<String>(
          title: Text("Not at all"),
          value: "Not at all",
          groupValue: q2Answer,
          onChanged: (val) {
            setState(() {
              q2Answer = val;
            });
          },
        ),
      ],
    );
  }

  // Q3: Show first random 4-digit sequence.
  Widget _buildQ3ShowDigitsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q3) Please remember the following 4-digit sequence:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
            randomDigits,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Text("You will be asked to type these digits on the next slide."),
      ],
    );
  }

  // Q3: Input answer for the first 4-digit sequence.
  Widget _buildQ3RecallDigitsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q3) Type the 4 digits you saw:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: q4Controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
      ],
    );
  }

  // Q4: Yes/No question for misplacing objects.
  Widget _buildQ4PageYesNo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q4) Do you frequently misplace everyday objects (like keys)?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        RadioListTile<String>(
          title: Text("Yes"),
          value: "Yes",
          groupValue: q5Answer,
          onChanged: (val) {
            setState(() {
              q5Answer = val;
            });
          },
        ),
        RadioListTile<String>(
          title: Text("No"),
          value: "No",
          groupValue: q5Answer,
          onChanged: (val) {
            setState(() {
              q5Answer = val;
            });
          },
        ),
      ],
    );
  }

  // Q5: Yes/No question for forgetting speech.
  Widget _buildQ5PageYesNo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q5) Do you sometimes forget what you were about to say?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        RadioListTile<String>(
          title: Text("Yes"),
          value: "Yes",
          groupValue: q6Answer,
          onChanged: (val) {
            setState(() {
              q6Answer = val;
            });
          },
        ),
        RadioListTile<String>(
          title: Text("No"),
          value: "No",
          groupValue: q6Answer,
          onChanged: (val) {
            setState(() {
              q6Answer = val;
            });
          },
        ),
      ],
    );
  }

  // Q6: Show the word "test".
  Widget _buildQ6ShowWordPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q6) Remember this word:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
            "test",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Text("You will be asked to type this word on the next slide."),
      ],
    );
  }

  // Q6: Input answer for word "test".
  Widget _buildQ6AnswerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q6) Type the word you just saw:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(controller: q7AnswerController),
      ],
    );
  }

  // Q7: Show the word "abc".
  Widget _buildQ7ShowWordPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q7) Remember this word:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
            "abc",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Text("You will be asked to type this word on the next slide."),
      ],
    );
  }

  // Q7: Input answer for word "abc".
  Widget _buildQ7AnswerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q7) Type the word you just saw:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(controller: q8AnswerController),
      ],
    );
  }

  // Q8: Show the word "xyz".
  Widget _buildQ8ShowWordPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q8) Remember this word:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
            "xyz",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Text("You will be asked to type this word on the next slide."),
      ],
    );
  }

  // Q8: Input answer for word "xyz".
  Widget _buildQ8AnswerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q8) Type the word you just saw:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(controller: q9AnswerController),
      ],
    );
  }

  // Q9: Show the word "hello".
  Widget _buildQ9ShowWordPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q9) Remember this word:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
            "hello",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Text("You will be asked to type this word on the next slide."),
      ],
    );
  }

  // Q9: Input answer for word "hello".
  Widget _buildQ9AnswerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q9) Type the word you just saw:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(controller: q10AnswerController),
      ],
    );
  }

  // NEW: Q10: Show a new random 4-digit sequence.
  Widget _buildq10NumberShowPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q10) Please remember the following 4-digit sequence:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
            randomDigits2,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Text("You will be asked to type these digits on the next slide."),
      ],
    );
  }

  // NEW: Q10: Input answer for the new 4-digit sequence.
  Widget _buildq10NumberRecallPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q10) Type the 4 digits you saw:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: newNumberController,
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
      ],
    );
  }

  // Q17: Score Display Page (centered with proper alignment).
  Widget _buildScorePage() {
    _calculateScore();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Test Completed",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            "Your Score: $_totalScore / 100",
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onTestComplete("Latest Score: $_totalScore / 100");
              Navigator.pop(context);
            },
            child: Text("Finish"),
          ),
        ],
      ),
    );
  }

  // ---- SCORING LOGIC ----
  void _calculateScore() {
    _totalScore = 0.0;

    // Q1 scoring.
    if (q1Answer == "Very Accurately") {
      _totalScore += 10;
    } else if (q1Answer == "Somewhat accurately") {
      _totalScore += 5;
    } else if (q1Answer == "Rarely accurately") {
      _totalScore += 2.5;
    }

    // Q2 scoring.
    if (q2Answer == "Very Accurately") {
      _totalScore += 10;
    } else if (q2Answer == "Somewhat accurately") {
      _totalScore += 5;
    } else if (q2Answer == "Rarely accurately") {
      _totalScore += 2.5;
    }

    // Q3/Q4: For each correctly recalled digit, add 2.5 points.
    String userTyped = q4Controller.text.trim();
    for (int i = 0; i < 4; i++) {
      if (i < userTyped.length && userTyped[i] == randomDigits[i]) {
        _totalScore += 2.5;
      }
    }

    // Q5: For the Yes/No question on misplacing objects.
    // Here, answering "No" is good (i.e. you don't misplace objects), so add 10 if "No".
    if (q5Answer == "No") {
      _totalScore += 10;
    }

    // Q6: For the Yes/No question on forgetting speech.
    // Similarly, add 10 if "No".
    if (q6Answer == "No") {
      _totalScore += 10;
    }

    // Q7/Q8: Expected word "test" (from q7AnswerController).
    String ansTest = q7AnswerController.text.trim().toLowerCase();
    if (ansTest == "test") {
      _totalScore += 10;
    } else if (ansTest.contains("tes")) {
      _totalScore += 5;
    }

    // Q9/Q10: Expected word "abc" (from q8AnswerController).
    String ansAbc = q8AnswerController.text.trim().toLowerCase();
    if (ansAbc == "abc") {
      _totalScore += 10;
    } else if (ansAbc.contains("ab")) {
      _totalScore += 5;
    }

    // Q11/Q12: Expected word "xyz" (from q9AnswerController).
    String ansXyz = q9AnswerController.text.trim().toLowerCase();
    if (ansXyz == "xyz") {
      _totalScore += 10;
    } else if (ansXyz.contains("xy")) {
      _totalScore += 5;
    }

    // Q13/Q14: Expected word "hello" (from q10AnswerController).
    String ansHello = q10AnswerController.text.trim().toLowerCase();
    if (ansHello == "hello") {
      _totalScore += 10;
    } else if (ansHello.contains("hell")) {
      _totalScore += 5;
    }

    // NEW: Q15/Q16: For the additional number question.
    String userTyped2 = newNumberController.text.trim();
    for (int i = 0; i < 4; i++) {
      if (i < userTyped2.length && userTyped2[i] == randomDigits2[i]) {
        _totalScore += 2.5;
      }
    }
  }

  // ---- UI Build ----
  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      appBar: AppBar(
        title: Text("Memory Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: pages[_currentQuestionIndex]),
            // Only show navigation buttons if not on the final score page.
            if (_currentQuestionIndex < pages.length - 1)
              SizedBox(height: 16),
            if (_currentQuestionIndex < pages.length - 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: Text("Back"),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex++;
                      });
                    },
                    child: Text("Next"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
