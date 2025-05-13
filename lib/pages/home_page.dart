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
  String searchQuery = '';
  String sortBy = 'Date';

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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search tasks...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Sorting dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Sort by: "),
                DropdownButton<String>(
                  value: sortBy,
                  items: ['Alphabetical', 'Date'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      sortBy = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),

          // Task list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('todos')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final tasks = snapshot.data!.docs;

                // Filter tasks based on search query
                final filteredTasks = tasks.where((task) {
                  final taskName = task['task'] as String;
                  return taskName.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                // Sort tasks
                if (sortBy == 'Alphabetical') {
                  filteredTasks.sort((a, b) => a['task'].compareTo(b['task']));
                } else if (sortBy == 'Date') {
                  filteredTasks.sort((a, b) {
                    final aDate = a['createdAt']?.toDate();
                    final bDate = b['createdAt']?.toDate();
                    return bDate!.compareTo(aDate!);
                  });
                }

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final taskData = filteredTasks[index];
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
          ),
        ],
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
