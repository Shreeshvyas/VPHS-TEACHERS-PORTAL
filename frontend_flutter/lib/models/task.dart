class Task {
  final int id;
  final int student;
  final String studentName;
  final String studentRoll;
  final String studentGrade;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.student,
    required this.studentName,
    required this.studentRoll,
    required this.studentGrade,
    required this.title,
    this.description,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      student: json['student'],
      studentName: json['student_name'] ?? '',
      studentRoll: json['student_roll'] ?? '',
      studentGrade: json['student_grade'] ?? '',
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student': student,
      'title': title,
      'description': description,
      'due_date': "${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}",
      'status': status,
    };
  }

  bool get isCompleted => status == 'COMPLETED';
}
