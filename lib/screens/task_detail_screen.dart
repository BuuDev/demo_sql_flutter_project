import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:demo_sql_flutter_project/models/task.dart';
import 'package:demo_sql_flutter_project/providers/task_provider.dart';
import 'package:demo_sql_flutter_project/services/notification_service.dart';
import 'dart:io' show Platform;

class TaskDetailScreen extends StatefulWidget {
  final Task? task;

  const TaskDetailScreen({super.key, this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _hasReminder = false;
  int _reminderMinutes = 0;
  final NotificationService _notificationService = NotificationService();
  bool _exactAlarmsPermitted = false;

  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': 'Đúng giờ', 'minutes': 0},
    {'label': '5 phút trước', 'minutes': 5},
    {'label': '15 phút trước', 'minutes': 15},
    {'label': '30 phút trước', 'minutes': 30},
    {'label': '1 giờ trước', 'minutes': 60},
    {'label': '2 giờ trước', 'minutes': 120},
    {'label': '1 ngày trước', 'minutes': 1440},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _hasReminder = widget.task!.hasReminder;
      _reminderMinutes = widget.task!.reminderMinutes;
    }

    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    await _notificationService.requestPermissions();
    if (Platform.isAndroid) {
      setState(() {
        _exactAlarmsPermitted = _notificationService.exactAlarmsPermitted;
      });
    } else {
      setState(() {
        _exactAlarmsPermitted = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dueDate.hour,
          _dueDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final task = widget.task != null
          ? widget.task!.copyWith(
              title: _titleController.text,
              description: _descriptionController.text,
              dueDate: _dueDate,
              updatedAt: now,
              hasReminder: _hasReminder,
              reminderMinutes: _reminderMinutes,
            )
          : Task(
              title: _titleController.text,
              description: _descriptionController.text,
              status: 0,
              dueDate: _dueDate,
              createdAt: now,
              updatedAt: now,
              hasReminder: _hasReminder,
              reminderMinutes: _reminderMinutes,
            );

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      if (widget.task != null) {
        taskProvider.updateTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        taskProvider.addTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    await _notificationService.openExactAlarmSettings();
    if (Platform.isAndroid) {
      setState(() {
        _exactAlarmsPermitted = _notificationService.exactAlarmsPermitted;
      });
    }
  }

  void _testReminder() {
    if (!_titleController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final testTask = Task(
      id: 9999,
      title: _titleController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : 'Test description',
      status: 0,
      dueDate: now.add(const Duration(minutes: 1)),
      createdAt: now,
      updatedAt: now,
      hasReminder: true,
      reminderMinutes: _reminderMinutes,
    );

    if (_reminderMinutes > 0) {
      _notificationService.showTestScheduledNotification(
        id: 9999,
        title: 'Test Reminder: ${testTask.title}',
        body:
            'This is a test reminder notification with $_reminderMinutes minute(s) advance notice',
        seconds: 5,
      );
    } else {
      _notificationService.showTestNotification(
        id: 9999,
        title: 'Test Reminder: ${testTask.title}',
        body: 'This is a test reminder notification for the exact due time',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_reminderMinutes > 0
            ? 'Test reminder scheduled for 5 seconds from now'
            : 'Test reminder sent immediately'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task != null ? 'Edit Task' : 'Add Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _testReminder,
            tooltip: 'Test Reminder',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Due Date: ', style: TextStyle(fontSize: 16)),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_dueDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectTime(context),
                      child: Text(
                        DateFormat('HH:mm').format(_dueDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Set Reminder'),
                  subtitle: Text(Platform.isAndroid && !_exactAlarmsPermitted
                      ? 'Reminders may not be exact (tap to fix)'
                      : 'Receive a notification for this task'),
                  value: _hasReminder,
                  onChanged: (value) {
                    setState(() {
                      _hasReminder = value;
                    });

                    if (value && Platform.isAndroid && !_exactAlarmsPermitted) {
                      _showExactAlarmPermissionDialog();
                    }
                  },
                ),
                if (_hasReminder) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                    child: Text(
                      'Remind me:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...List.generate(_reminderOptions.length, (index) {
                    final option = _reminderOptions[index];
                    return RadioListTile<int>(
                      title: Text(option['label']),
                      value: option['minutes'],
                      groupValue: _reminderMinutes,
                      onChanged: (value) {
                        setState(() {
                          _reminderMinutes = value!;
                        });
                      },
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: _testReminder,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Test Reminder Now'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    child: Text(
                      widget.task != null ? 'Update Task' : 'Add Task',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExactAlarmPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exact Alarm Permission'),
        content: const Text(
            'For precise reminders, this app needs permission to schedule exact alarms. '
            'Without this permission, reminders may be delayed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestExactAlarmPermission();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}
