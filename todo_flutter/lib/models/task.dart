class Task {
  final String id;
  final String user;
  final String title;
  final String description;
  final String status;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.user,
    required this.title,
    required this.description,
    required this.status,
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'],
      user: json['user'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
    );
  }
}
