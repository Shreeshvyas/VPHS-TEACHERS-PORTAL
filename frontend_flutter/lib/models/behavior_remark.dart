class BehaviorRemark {
  final int id;
  final int student;
  final String studentName;
  final String studentRoll;
  final String studentGrade;
  final String type; // POSITIVE | WARNING
  final String title;
  final String? description;
  final DateTime createdAt;

  BehaviorRemark({
    required this.id,
    required this.student,
    required this.studentName,
    required this.studentRoll,
    required this.studentGrade,
    required this.type,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory BehaviorRemark.fromJson(Map<String, dynamic> json) {
    return BehaviorRemark(
      id: json['id'],
      student: json['student'],
      studentName: json['student_name'] ?? '',
      studentRoll: json['student_roll'] ?? '',
      studentGrade: json['student_grade'] ?? '',
      type: json['type'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student': student,
      'type': type,
      'title': title,
      'description': description,
    };
  }

  bool get isPositive => type == 'POSITIVE';
}
