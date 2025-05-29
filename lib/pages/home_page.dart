import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple_todo/pages/profile_page.dart';
import 'package:simple_todo/pages/settings_page.dart';
import 'package:simple_todo/pages/todo_description_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:simple_todo/providers/theme_provider.dart';
import 'package:simple_todo/pages/about_us_page.dart';


import 'map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late PageController _pageController;
  int _selectedIndex = 0;
  String searchQuery = '';
  String sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void saveNewTask() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final descriptionController = TextEditingController();
        final locationController = TextEditingController();
        DateTime? plannedDate;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.addNewTask),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.taskTitle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.taskDescription,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      hintText: 'Enter location (optional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plannedDate == null
                              ? 'No date selected'
                              : 'Planned date: ${plannedDate!.toLocal().toString().split(' ')[0]}',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final now = DateTime.now();
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now.subtract(const Duration(days: 365)),
                            lastDate: now.add(const Duration(days: 365 * 5)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              plannedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final description = descriptionController.text.trim();
                  final location = locationController.text.trim();

                  if (title.isNotEmpty) {
                    final taskData = {
                      'task': title,
                      'description': description,
                      'completed': false,
                      'createdAt': FieldValue.serverTimestamp(),
                      'userId': user.uid,
                    };

                    if (location.isNotEmpty) {
                      taskData['location'] = location;
                    }

                    if (plannedDate != null) {
                      taskData['plannedDate'] = Timestamp.fromDate(plannedDate!);
                    }

                    _firestore.collection('todos').add(taskData);
                  }

                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
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

  Widget _buildTodoPage({bool withoutAppBar = false}) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isPurpleTheme = themeProvider.currentTheme == 'purple';

    return Scaffold(
      backgroundColor: isPurpleTheme
          ? Colors.deepPurple.shade50
          : themeProvider.currentTheme == 'dark'
          ? Colors.grey.shade900
          : Colors.white,

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.searchTasks,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: isPurpleTheme,
                fillColor: Colors.white,
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
                Text("${AppLocalizations.of(context)!.sortBy}: "),
                DropdownButton<String>(
                  value: sortBy,
                  items: [
                    DropdownMenuItem(
                      value: 'alphabetical',
                      child: Text(AppLocalizations.of(context)!.alphabetical),
                    ),
                    DropdownMenuItem(
                      value: 'date',
                      child: Text(AppLocalizations.of(context)!.date),
                    ),
                  ],
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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!.docs;

                // Filter tasks
                final filteredTasks = tasks.where((task) {
                  final taskName = task['task'] as String;
                  return taskName.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                // Sort tasks
                if (sortBy == 'alphabetical') {
                  filteredTasks.sort((a, b) => a['task'].compareTo(b['task']));
                } else if (sortBy == 'date') {
                  filteredTasks.sort((a, b) {
                    final aTimestamp = a['createdAt'];
                    final bTimestamp = b['createdAt'];

                    if (aTimestamp == null && bTimestamp == null) return 0;
                    if (aTimestamp == null) return 1;
                    if (bTimestamp == null) return -1;

                    final aDate = aTimestamp.toDate();
                    final bDate = bTimestamp.toDate();
                    return bDate.compareTo(aDate); // Most recent first
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

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 20),
                            child: child,
                          ),
                        );
                      },
                      child: Dismissible(
                        key: Key(taskId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => deleteTask(taskId),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    TodoDescriptionPage(
                                      title: taskName,
                                      description: taskDescription,
                                    ),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  final fadeAnimation = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeIn,
                                  );
                                  return FadeTransition(
                                    opacity: fadeAnimation,
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          child: Container(
                            margin:
                            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 7.0),
                            height: 60,
                            decoration: BoxDecoration(
                              color: isPurpleTheme
                                  ? Colors.deepPurple
                                  : themeProvider.currentTheme == 'dark'
                                  ? Colors.black
                                  : Colors.lightBlueAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                                title: Text(
                                  taskName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: taskCompleted
                                        ? TextDecoration.combine([
                                      TextDecoration.lineThrough,
                                    ])
                                        : null,
                                    decorationColor: Colors.white,
                                    decorationThickness: 2.0, // Adjust this value to make it thicker
                                    decorationStyle: TextDecorationStyle.solid,
                                  ),
                                ),
                              leading: Checkbox(
                                value: taskCompleted,
                                onChanged: (value) => toggleTask(taskId, taskCompleted),
                                activeColor: Colors.white,
                                checkColor: isPurpleTheme ||
                                    themeProvider.currentTheme == 'dark'
                                    ? Colors.deepPurple
                                    : Colors.lightBlueAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );

              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isPurpleTheme = themeProvider.currentTheme == 'purple';



    return Scaffold(
      appBar: AppBar(
        backgroundColor: isPurpleTheme
            ? Colors.deepPurple
            : themeProvider.currentTheme == 'dark'
            ? Colors.black
            : Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        title: Text(loc.appTitle),
        actions: _selectedIndex == 1
            ? [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: loc.logout,
          ),
        ]
            : null,
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildTodoPage(withoutAppBar: true),
          const ProfilePage(),
          const SettingsPage(),
          const MapPage(),
          const AboutUsPage()
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isPurpleTheme
            ? Colors.white
            : themeProvider.currentTheme == 'dark'
            ? Colors.black
            : Colors.lightBlueAccent,
        selectedItemColor: isPurpleTheme
            ? Colors.deepPurple
            : themeProvider.currentTheme == 'dark'
            ? Colors.deepPurple
            : Colors.lightBlueAccent,
        unselectedItemColor: isPurpleTheme
            ? Colors.grey
            : themeProvider.currentTheme == 'dark'
            ? Colors.white
            : Colors.black,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: loc.tasks),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: loc.profile),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: loc.settings),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: loc.map),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: loc.about)
        ],
      ),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: saveNewTask,
        backgroundColor: isPurpleTheme
            ? Colors.deepPurple
            : themeProvider.currentTheme == 'dark'
            ? Colors.black
            : Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}