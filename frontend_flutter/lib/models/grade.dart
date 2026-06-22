class Grade {
  final int id;
  final int student;
  final String studentName;
  final String studentRoll;
  final String studentGrade;
  final String examName;
  final String subject;
  final double marksObtained;
  final double maxMarks;
  final String? remarks;
  final double percentage;
  final String gradeLetter;
  final DateTime createdAt;

  Grade({
    required this.id,
    required this.student,
    required this.studentName,
    required this.studentRoll,
    required this.studentGrade,
    required this.examName,
    required this.subject,
    required this.marksObtained,
    required this.maxMarks,
    this.remarks,
    required this.percentage,
    required this.gradeLetter,
    required this.createdAt,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      student: json['student'],
      studentName: json['student_name'] ?? '',
      studentRoll: json['student_roll'] ?? '',
      studentGrade: json['student_grade'] ?? '',
      examName: json['exam_name'],
      subject: json['subject'],
      marksObtained: (json['marks_obtained'] as num).toDouble(),
      maxMarks: (json['max_marks'] as num).toDouble(),
      remarks: json['remarks'],
      percentage: (json['percentage'] as num).toDouble(),
      gradeLetter: json['grade_letter'] ?? 'F',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student': student,
      'exam_name': examName,
      'subject': subject,
      'marks_obtained': marksObtained,
      'max_marks': maxMarks,
      'remarks': remarks,
    };
  }
}
