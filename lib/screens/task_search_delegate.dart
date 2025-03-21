import 'package:demo_sql_flutter_project/providers/task_provider.dart';
import 'package:demo_sql_flutter_project/screens/task_detail_screen.dart';
import 'package:demo_sql_flutter_project/widgets/task_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
