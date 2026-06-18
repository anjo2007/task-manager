import 'dart:convert';

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String description;
  final String notes;
  final DateTime dueDate;
  final TaskPriority priority;
  final String category;
  final bool isCompleted;
  final List<String> imageAttachments; // base64 encoded strings
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.notes = '',
    required this.dueDate,
    this.priority = TaskPriority.medium,
    required this.category,
    this.isCompleted = false,
    this.imageAttachments = const [],
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? notes,
    DateTime? dueDate,
    TaskPriority? priority,
    String? category,
    bool? isCompleted,
    List<String>? imageAttachments,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      imageAttachments: imageAttachments ?? this.imageAttachments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'notes': notes,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'category': category,
      'isCompleted': isCompleted,
      'imageAttachments': imageAttachments,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      notes: map['notes'] ?? '',
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      category: map['category'] ?? 'General',
      isCompleted: map['isCompleted'] ?? false,
      imageAttachments: List<String>.from(map['imageAttachments'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}
