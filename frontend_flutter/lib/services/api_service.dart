import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/task.dart';
import '../models/grade.dart';
import '../models/behavior_remark.dart';
import '../models/notice.dart';

class ApiService {
  static String baseUrl = 'http://127.0.0.1:8000/api';

  static Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  static void setBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }

  // 1. Authenticate Teacher
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(null),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMsg = jsonDecode(response.body)['non_field_errors']?[0] ?? 'Login failed';
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  // 2. Fetch Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats(String token) async {
    final url = Uri.parse('$baseUrl/dashboard/');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch dashboard stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 3. Fetch Students List
  Future<List<Student>> getStudents(String token) async {
    final url = Uri.parse('$baseUrl/students/');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        List jsonList = jsonDecode(response.body);
        return jsonList.map((s) => Student.fromJson(s)).toList();
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 4. Create Student
  Future<Student> addStudent(
    String token,
    String name,
    String rollNumber,
    String grade,
    String? email,
    String? guardianName,
    String? guardianPhone,
  ) async {
    final url = Uri.parse('$baseUrl/students/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'name': name,
          'roll_number': rollNumber,
          'grade': grade,
          'email': email,
          'guardian_name': guardianName,
          'guardian_phone': guardianPhone,
        }),
      );

      if (response.statusCode == 201) {
        return Student.fromJson(jsonDecode(response.body));
      } else {
        final errors = jsonDecode(response.body);
        String msg = 'Failed to create student';
        if (errors is Map) {
          msg = errors.values.map((v) => v.toString()).join(', ');
        }
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 5. Delete Student
  Future<void> deleteStudent(String token, int studentId) async {
    final url = Uri.parse('$baseUrl/students/$studentId/');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete student');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 6. Fetch Tasks List
  Future<List<Task>> getTasks(String token) async {
    final url = Uri.parse('$baseUrl/tasks/');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        List jsonList = jsonDecode(response.body);
        return jsonList.map((t) => Task.fromJson(t)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 7. Create Task
  Future<Task> addTask(
    String token,
    int studentId,
    String title,
    String? description,
    String dueDate,
  ) async {
    final url = Uri.parse('$baseUrl/tasks/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'student': studentId,
          'title': title,
          'description': description,
          'due_date': dueDate,
          'status': 'PENDING',
        }),
      );

      if (response.statusCode == 201) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        final errors = jsonDecode(response.body);
        String msg = 'Failed to assign task';
        if (errors is Map) {
          msg = errors.values.map((v) => v.toString()).join(', ');
        }
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 8. Mark Task as Completed
  Future<Task> completeTask(String token, int taskId) async {
    final url = Uri.parse('$baseUrl/tasks/$taskId/');
    try {
      final response = await http.patch(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'status': 'COMPLETED',
        }),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ==========================================
  // UPGRADED FEATURE APIS
  // ==========================================

  // 9. Batch Save Attendance
  Future<void> saveAttendanceBatch(String token, String dateString, List<Map<String, dynamic>> records) async {
    final url = Uri.parse('$baseUrl/attendance/batch/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'date': dateString,
          'records': records,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save attendance roster');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 10. Fetch Grades Roster
  Future<List<Grade>> getGrades(String token) async {
    final url = Uri.parse('$baseUrl/grades/');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        List jsonList = jsonDecode(response.body);
        return jsonList.map((g) => Grade.fromJson(g)).toList();
      } else {
        throw Exception('Failed to load grades');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 11. Add Grade Score
  Future<Grade> addGrade(
    String token,
    int studentId,
    String examName,
    String subject,
    double marksObtained,
    double maxMarks,
    String? remarks,
  ) async {
    final url = Uri.parse('$baseUrl/grades/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'student': studentId,
          'exam_name': examName,
          'subject': subject,
          'marks_obtained': marksObtained,
          'max_marks': maxMarks,
          'remarks': remarks,
        }),
      );

      if (response.statusCode == 201) {
        return Grade.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to log grade scores');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 12. Fetch Behavior Remarks Roster
  Future<List<BehaviorRemark>> getBehaviorRemarks(String token) async {
    final url = Uri.parse('$baseUrl/remarks/');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        List jsonList = jsonDecode(response.body);
        return jsonList.map((r) => BehaviorRemark.fromJson(r)).toList();
      } else {
        throw Exception('Failed to load remarks');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 13. Add Behavior Remark Conduct Review
  Future<BehaviorRemark> addBehaviorRemark(
    String token,
    int studentId,
    String type,
    String title,
    String? description,
  ) async {
    final url = Uri.parse('$baseUrl/remarks/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'student': studentId,
          'type': type,
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return BehaviorRemark.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to log conduct feedback');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 14. Fetch Notices Feed List
  Future<List<Notice>> getNotices(String token) async {
    final url = Uri.parse('$baseUrl/notices/');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        List jsonList = jsonDecode(response.body);
        return jsonList.map((n) => Notice.fromJson(n)).toList();
      } else {
        throw Exception('Failed to load noticeboard feed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 15. Broadcast Notice
  Future<Notice> addNotice(String token, String title, String content) async {
    final url = Uri.parse('$baseUrl/notices/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'title': title,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        return Notice.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to broadcast announcement');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 16. Delete Notice
  Future<void> deleteNotice(String token, int noticeId) async {
    final url = Uri.parse('$baseUrl/notices/$noticeId/');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete announcement');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
