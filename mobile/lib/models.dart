enum TaskStatus { active, paused, done }

TaskStatus taskStatusFromString(String s) {
  return TaskStatus.values.firstWhere((e) => e.name == s, orElse: () => TaskStatus.active);
}

class Dimension {
  final int id;
  final String name;
  final String createdAt;

  Dimension({required this.id, required this.name, required this.createdAt});

  factory Dimension.fromJson(Map<String, dynamic> json) => Dimension(
    id: json['id'] as int,
    name: json['name'] as String,
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'created_at': createdAt};
}

class Task {
  final int id;
  final String title;
  final String description;
  final int? dimensionId;
  final String? dimensionName;
  final TaskStatus status;
  final String createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dimensionId,
    required this.dimensionName,
    required this.status,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as int,
    title: json['title'] as String,
    description: (json['description'] as String?) ?? '',
    dimensionId: json['dimension_id'] as int?,
    dimensionName: json['dimension_name'] as String?,
    status: taskStatusFromString(json['status'] as String),
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dimension_id': dimensionId,
    'dimension_name': dimensionName,
    'status': status.name,
    'created_at': createdAt,
  };
}

class Entry {
  final int id;
  final int dimensionId;
  final String date; // YYYY-MM-DD
  final int score; // 0-4
  final String note;
  final String createdAt;
  final String updatedAt;
  final String dimensionName;

  Entry({
    required this.id,
    required this.dimensionId,
    required this.date,
    required this.score,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.dimensionName,
  });

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
    id: json['id'] as int,
    dimensionId: json['dimension_id'] as int,
    date: json['date'] as String,
    score: json['score'] as int,
    note: (json['note'] as String?) ?? '',
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    dimensionName: json['dimension_name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dimension_id': dimensionId,
    'date': date,
    'score': score,
    'note': note,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'dimension_name': dimensionName,
  };
}

class DayNote {
  final String date; // YYYY-MM-DD
  final String note;
  final String createdAt;
  final String updatedAt;

  DayNote({required this.date, required this.note, required this.createdAt, required this.updatedAt});

  factory DayNote.fromJson(Map<String, dynamic> json) => DayNote(
    date: json['date'] as String,
    note: (json['note'] as String?) ?? '',
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'note': note,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class TaskCompletion {
  final int id;
  final int taskId;
  final String date;
  final String createdAt;
  final String taskTitle;

  TaskCompletion({
    required this.id,
    required this.taskId,
    required this.date,
    required this.createdAt,
    required this.taskTitle,
  });

  factory TaskCompletion.fromJson(Map<String, dynamic> json) => TaskCompletion(
    id: json['id'] as int,
    taskId: json['task_id'] as int,
    date: json['date'] as String,
    createdAt: json['created_at'] as String,
    taskTitle: (json['task_title'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'task_id': taskId,
    'date': date,
    'created_at': createdAt,
    'task_title': taskTitle,
  };
}
