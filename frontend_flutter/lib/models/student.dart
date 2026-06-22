import 'task.dart';
import 'attendance.dart';
import 'grade.dart';
import 'behavior_remark.dart';

class Student {
  final int id;
  final int teacher;
  final String name;
  final String rollNumber;
  final String grade;
  final String? email;
  final String? guardianName;
  final String? guardianPhone;
  final DateTime createdAt;
  final List<Task> tasks;
  final List<Attendance> attendances;
  final List<Grade> grades;
  final List<BehaviorRemark> behaviorRemarks;
  final int taskCount;
  final int pendingTaskCount;
  final double attendancePercentage;
  final double averageGrade;

  Student({
    required this.id,
    required this.teacher,
    required this.name,
    required this.rollNumber,
    required this.grade,
    this.email,
    this.guardianName,
    this.guardianPhone,
    required this.createdAt,
    required this.tasks,
    required this.attendances,
    required this.grades,
    required this.behaviorRemarks,
    required this.taskCount,
    required this.pendingTaskCount,
    required this.attendancePercentage,
    required this.averageGrade,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    var taskJsonList = json['tasks'] as List? ?? [];
    List<Task> taskList = taskJsonList.map((i) => Task.fromJson(i)).toList();

    var attJsonList = json['attendances'] as List? ?? [];
    List<Attendance> attList = attJsonList.map((i) => Attendance.fromJson(i)).toList();

    var gradeJsonList = json['grades'] as List? ?? [];
    List<Grade> gradeList = gradeJsonList.map((i) => Grade.fromJson(i)).toList();

    var remarkJsonList = json['behavior_remarks'] as List? ?? [];
    List<BehaviorRemark> remarkList = remarkJsonList.map((i) => BehaviorRemark.fromJson(i)).toList();

    return Student(
      id: json['id'],
      teacher: json['teacher'],
      name: json['name'],
      rollNumber: json['roll_number'],
      grade: json['grade'],
      email: json['email'],
      guardianName: json['guardian_name'],
      guardianPhone: json['guardian_phone'],
      createdAt: DateTime.parse(json['created_at']),
      tasks: taskList,
      attendances: attList,
      grades: gradeList,
      behaviorRemarks: remarkList,
      taskCount: json['task_count'] ?? 0,
      pendingTaskCount: json['pending_task_count'] ?? 0,
      attendancePercentage: (json['attendance_percentage'] as num? ?? 100.0).toDouble(),
      averageGrade: (json['average_grade'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher': teacher,
      'name': name,
      'roll_number': rollNumber,
      'grade': grade,
      'email': email,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
    };
  }
}
