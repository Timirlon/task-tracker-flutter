import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple_todo/pages/profile_page.dart';
import 'package:simple_todo/pages/todo_description_page.dart';
import 'package:simple_todo/utils/todo_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void saveNewTask() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final descriptionController = TextEditingController();

        return AlertDialog(
          title: const Text("Add New Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Task title',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Task description',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();

                if (title.isNotEmpty) {
                  _firestore.collection('todos').add({
                    'task': title,
                    'description': description,
                    'completed': false,
                    'createdAt': FieldValue.serverTimestamp(),
                    'userId': user.uid
                  });
                }

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void toggleTask(String id, bool currentValue) {
    _firestore.collection('todos').doc(id).update({
      'completed': !currentValue,
    });
  }

  void deleteTask(String id) {
    _firestore.collection('todos').doc(id).delete();
  }

  Widget _buildTodoPage() {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade300,
      appBar: AppBar(
        title: const Text('Task Tracker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('todos')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final taskData = tasks[index];
              final taskId = taskData.id;
              final taskName = taskData['task'];
              final taskCompleted = taskData['completed'];
              final taskDescription = taskData['description'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TodoDescriptionPage(
                        title: taskName,
                        description: taskDescription,
                      ),
                    ),
                  );
                },
                child: TodoList(
                  taskName: taskName,
                  taskCompleted: taskCompleted,
                  onChanged: (value) => toggleTask(taskId, taskCompleted),
                  deleteFunction: (_) => deleteTask(taskId),
                ),
              );
            },
          );
        },
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: saveNewTask,
          child: const Icon(Icons.add),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildTodoPage(), const ProfilePage()];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
