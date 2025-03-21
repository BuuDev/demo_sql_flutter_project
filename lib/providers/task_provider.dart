import 'package:flutter/foundation.dart';
import 'package:demo_sql_flutter_project/helpers/database_helper.dart';
import 'package:demo_sql_flutter_project/models/task.dart';
import 'package:demo_sql_flutter_project/services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _showOnlyPending = false;
  String _searchQuery = '';

  List<Task> get tasks => _filteredTasks;
  bool get showOnlyPending => _showOnlyPending;
  String get searchQuery => _searchQuery;

  TaskProvider() {
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    _tasks = await _databaseHelper.getTasks();
    _applyFilters();
  }

  Future<void> addTask(Task task) async {
    final id = await _databaseHelper.insertTask(task);

    if (task.hasReminder) {
      try {
        final taskWithId = task.copyWith(id: id);

        if (taskWithId.reminderMinutes > 0) {
          await _notificationService.scheduleTaskReminder(taskWithId,
              reminderTime: Duration(minutes: taskWithId.reminderMinutes));
        } else {
          await _notificationService.scheduleTaskReminder(taskWithId);
        }
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }

    await _fetchTasks();
  }

  Future<void> updateTask(Task task) async {
    await _databaseHelper.updateTask(task);

    try {
      if (task.hasReminder) {
        if (task.reminderMinutes > 0) {
          await _notificationService.scheduleTaskReminder(task,
              reminderTime: Duration(minutes: task.reminderMinutes));
        } else {
          await _notificationService.scheduleTaskReminder(task);
        }
      } else if (task.id != null) {
        await _notificationService.cancelNotification(task.id!);
      }
    } catch (e) {
      debugPrint('Error handling notification: $e');
    }

    await _fetchTasks();
  }

  Future<void> deleteTask(int id) async {
    await _databaseHelper.deleteTask(id);
    await _notificationService.cancelNotification(id);
    await _fetchTasks();
  }

  Future<void> toggleTaskStatus(Task task) async {
    final updatedTask = task.copyWith(
      status: task.status == 0 ? 1 : 0,
      updatedAt: DateTime.now(),
    );

    if (updatedTask.status == 1 &&
        updatedTask.hasReminder &&
        updatedTask.id != null) {
      await _notificationService.cancelNotification(updatedTask.id!);
    } else if (updatedTask.status == 0 && updatedTask.hasReminder) {
      if (updatedTask.reminderMinutes > 0) {
        await _notificationService.scheduleTaskReminder(updatedTask,
            reminderTime: Duration(minutes: updatedTask.reminderMinutes));
      } else {
        await _notificationService.scheduleTaskReminder(updatedTask);
      }
    }

    await updateTask(updatedTask);
  }

  Future<void> toggleReminder(Task task) async {
    final updatedTask = task.copyWith(
      hasReminder: !task.hasReminder,
      updatedAt: DateTime.now(),
    );

    await updateTask(updatedTask);
  }

  void toggleFilter() {
    _showOnlyPending = !_showOnlyPending;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    if (_searchQuery.isNotEmpty) {
      _filteredTasks = _tasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    } else {
      _filteredTasks = _tasks;
    }

    if (_showOnlyPending) {
      _filteredTasks =
          _filteredTasks.where((task) => task.status == 0).toList();
    }

    notifyListeners();
  }
}
