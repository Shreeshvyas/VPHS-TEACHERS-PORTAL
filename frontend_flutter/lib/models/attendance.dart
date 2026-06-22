class Attendance {
  final int id;
  final int student;
  final String studentName;
  final String studentRoll;
  final String studentGrade;
  final DateTime date;
  final String status; // PRESENT | ABSENT | LATE | LEAVE
  final String? remarks;

  Attendance({
    required this.id,
    required this.student,
    required this.studentName,
    required this.studentRoll,
    required this.studentGrade,
    required this.date,
    required this.status,
    this.remarks,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      student: json['student'],
      studentName: json['student_name'] ?? '',
      studentRoll: json['student_roll'] ?? '',
      studentGrade: json['student_grade'] ?? '',
      date: DateTime.parse(json['date']),
      status: json['status'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student': student,
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'status': status,
      'remarks': remarks,
    };
  }
}
