import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo_sql_flutter_project/models/task.dart';
import 'package:demo_sql_flutter_project/providers/task_provider.dart';
import 'package:demo_sql_flutter_project/providers/theme_provider.dart';
import 'package:demo_sql_flutter_project/screens/task_detail_screen.dart';
import 'package:demo_sql_flutter_project/services/notification_service.dart';
import 'package:demo_sql_flutter_project/widgets/task_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(),
              );
            },
          ),
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return IconButton(
                icon: Icon(
                  taskProvider.showOnlyPending
                      ? Icons.filter_list_off
                      : Icons.filter_list,
                ),
                onPressed: () {
                  taskProvider.toggleFilter();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        taskProvider.showOnlyPending
                            ? 'Showing pending tasks only'
                            : 'Showing all tasks',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          // Add test notification button
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showTestNotificationOptions(context, notificationService);
            },
            tooltip: 'Test Notifications',
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final tasks = taskProvider.tasks;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    taskProvider.showOnlyPending
                        ? 'No pending tasks'
                        : 'No tasks yet',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TaskDetailScreen(),
                        ),
                      );
                    },
                    child: const Text('Add a task'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskItem(
                task: task,
                onToggle: () {
                  taskProvider.toggleTaskStatus(task);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        task.status == 0
                            ? 'Task marked as completed'
                            : 'Task marked as pending',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(task: task),
                    ),
                  );
                },
                onDelete: () {
                  _showDeleteConfirmation(context, task);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskDetailScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<TaskProvider>(context, listen: false)
                  .deleteTask(task.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTestNotificationOptions(
      BuildContext context, NotificationService notificationService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notifications'),
        content: const Text('Choose a notification type to test:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notificationService.showTestNotification(
                title: 'Test Notification',
                body: 'This is an immediate test notification',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Immediate notification sent'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Immediate'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notificationService.showTestScheduledNotification(
                title: 'Test Scheduled Notification',
                body: 'This notification was scheduled for 5 seconds later',
                seconds: 5,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Notification scheduled for 5 seconds from now'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Scheduled (5s)'),
          ),
        ],
      ),
    );
  }
}

class TaskSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.setSearchQuery(query);

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;

        if (tasks.isEmpty) {
          return const Center(
            child: Text('No tasks found'),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskItem(
              task: task,
              onToggle: () {
                taskProvider.toggleTaskStatus(task);
              },
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(task: task),
                  ),
                );
              },
              onDelete: () {
                taskProvider.deleteTask(task.id!);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Search for tasks'),
      );
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.setSearchQuery(query);

    return buildResults(context);
  }
}
