import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/task.dart';
import '../models/grade.dart';
import '../models/behavior_remark.dart';
import '../models/notice.dart';

class ApiService {
  static String baseUrl = 'https://teacher.vyaspublicschool.in/api';

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

  // 17. Update Teacher Profile (Multipart upload for photos/documents)
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String classAssigned,
    required String esicId,
    required String bankAccount,
    required String bankName,
    required String ifsc,
    String? employeeId,
    String? profilePicPath,
    String? docPath,
  }) async {
    final url = Uri.parse('$baseUrl/profile/');
    try {
      final request = http.MultipartRequest('PUT', url);
      request.headers.addAll({
        'Authorization': 'Token $token',
        'Accept': 'application/json',
      });
      
      request.fields.addAll({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'class_assigned': classAssigned,
        'esic_id': esicId,
        'bank_account_number': bankAccount,
        'bank_name': bankName,
        'ifsc_code': ifsc,
      });

      if (employeeId != null) {
        request.fields['employee_id'] = employeeId;
      }

      if (profilePicPath != null && profilePicPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('profile_picture', profilePicPath));
      }
      if (docPath != null && docPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('document_file', docPath));
      }

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error updating profile: $e');
    }
  }

  // 18. Fetch All Teachers (Super Admin only)
  Future<List<dynamic>> getAllTeachers(String token) async {
    final url = Uri.parse('$baseUrl/teachers/');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch teachers directory');
      }
    } catch (e) {
      throw Exception('Network error fetching teachers: $e');
    }
  }

  // 19. Update Teacher Profile by Admin (Super Admin only)
  Future<Map<String, dynamic>> updateTeacherByAdmin({
    required String token,
    required int teacherId,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$baseUrl/teachers/$teacherId/');
    try {
      final response = await http.patch(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update teacher: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error updating teacher: $e');
    }
  }

  // 20. Change password
  Future<void> changePassword(String token, String oldPassword, String newPassword) async {
    final url = Uri.parse('$baseUrl/profile/change-password/');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final errorMsg = body['error'] ?? 'Failed to update password';
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  // 21. Get profile detail
  Future<Map<String, dynamic>> getProfile(String token) async {
    final url = Uri.parse('$baseUrl/profile/');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Network error loading profile: $e');
    }
  }

  // 22. Upload document
  Future<Map<String, dynamic>> uploadDocument(String token, String docPath, String name) async {
    final url = Uri.parse('$baseUrl/profile/documents/');
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Token $token',
        'Accept': 'application/json',
      });
      request.fields['name'] = name;
      request.files.add(await http.MultipartFile.fromPath('file', docPath));

      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload document: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error uploading document: $e');
    }
  }

  // 23. Delete document
  Future<void> deleteDocument(String token, int docId) async {
    final url = Uri.parse('$baseUrl/profile/documents/$docId/');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      );
      if (response.statusCode != 204) {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      throw Exception('Network error deleting document: $e');
    }
  }
}
