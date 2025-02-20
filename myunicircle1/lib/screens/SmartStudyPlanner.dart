import 'package:flutter/material.dart';

class SmartStudyPlanner extends StatefulWidget {
  const SmartStudyPlanner({super.key});

  @override
  _SmartStudyPlannerState createState() => _SmartStudyPlannerState();
}

class _SmartStudyPlannerState extends State<SmartStudyPlanner> {
  TextEditingController subjectController = TextEditingController();
  TextEditingController deadlineController = TextEditingController();
  TextEditingController availableTimeController = TextEditingController();

  List<Map<String, String>> studyPlan = [];

  void _addStudyTask() {
    if (subjectController.text.isNotEmpty &&
        deadlineController.text.isNotEmpty) {
      setState(() {
        studyPlan.add({
          "subject": subjectController.text,
          "deadline": deadlineController.text,
          "time":
              availableTimeController.text.isNotEmpty
                  ? "${availableTimeController.text} hours"
                  : "Not specified",
        });
      });
      subjectController.clear();
      deadlineController.clear();
      availableTimeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: const Text("Smart Study Planner"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Plan Your Study Schedule",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            // Subject Input
            TextField(
              controller: subjectController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Subject Name"),
            ),
            const SizedBox(height: 10),

            // Deadline Input
            TextField(
              controller: deadlineController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Deadline (YYYY-MM-DD)"),
            ),
            const SizedBox(height: 10),

            // Available Study Time Input
            TextField(
              controller: availableTimeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Available Study Time (Hours)"),
            ),
            const SizedBox(height: 15),

            // Add Task Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addStudyTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F56BB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Add to Study Plan",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Study Plan List
            const Text(
              "Your Study Plan:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: studyPlan.length,
                itemBuilder: (context, index) {
                  final task = studyPlan[index];
                  return Card(
                    color: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.book, color: Color(0xFF7F56BB)),
                      title: Text(
                        task["subject"]!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Deadline: ${task["deadline"]} | Time: ${task["time"]}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            studyPlan.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
