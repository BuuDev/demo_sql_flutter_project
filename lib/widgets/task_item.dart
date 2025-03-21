import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:demo_sql_flutter_project/models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = task.status == 1;
    final bool isOverdue =
        task.dueDate.isBefore(DateTime.now()) && !isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isCompleted,
                  onChanged: (_) => onToggle(),
                ),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : null,
                    ),
                  ),
                ),
                if (task.hasReminder)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Tooltip(
                      message: task.reminderMinutes > 0
                          ? 'Reminder: ${_formatReminderTime(task.reminderMinutes)} before due time'
                          : 'Reminder: At due time',
                      child: const Icon(Icons.notifications_active,
                          size: 18, color: Colors.amber),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Text(
                  task.description,
                  style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 40.0, top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy - HH:mm').format(task.dueDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isOverdue ? Colors.red : Colors.grey,
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReminderTime(int minutes) {
    if (minutes >= 1440) {
      return '${minutes ~/ 1440} day(s)';
    } else if (minutes >= 60) {
      return '${minutes ~/ 60} hour(s)';
    } else {
      return '$minutes minute(s)';
    }
  }
}
