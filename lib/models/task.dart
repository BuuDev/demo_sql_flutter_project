class Task {
  final int? id;
  final String title;
  final String description;
  final int status;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasReminder;
  final int reminderMinutes;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.hasReminder = false,
    this.reminderMinutes = 0,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    int? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasReminder,
    int? reminderMinutes,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'has_reminder': hasReminder ? 1 : 0,
      'reminder_minutes': reminderMinutes,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      dueDate: DateTime.parse(map['due_date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      hasReminder: map['has_reminder'] == 1,
      reminderMinutes: map['reminder_minutes'] ?? 0,
    );
  }
}
