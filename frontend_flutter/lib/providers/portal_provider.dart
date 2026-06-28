import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/task.dart';
import '../models/grade.dart';
import '../models/behavior_remark.dart';
import '../models/notice.dart';
import '../services/api_service.dart';

class PortalProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _token;
  Map<String, dynamic>? _currentUser;
  
  List<Student> _students = [];
  List<Task> _tasks = [];
  List<Grade> _grades = [];
  List<BehaviorRemark> _remarks = [];
  List<Notice> _notices = [];
  List<dynamic> _teachers = [];
  
  Map<String, dynamic>? _dashboardStats;
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDarkMode = true;

  PortalProvider() {
    _loadThemePref();
  }

  // Getters
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  
  List<Student> get students => _students;
  List<Task> get tasks => _tasks;
  List<Grade> get grades => _grades;
  List<BehaviorRemark> get remarks => _remarks;
  List<Notice> get notices => _notices;
  List<dynamic> get teachers => _teachers;
  
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void updateApiUrl(String newUrl) {
    ApiService.setBaseUrl(newUrl);
    notifyListeners();
  }

  // 1. Authenticate Teacher User
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.login(username, password);
      _token = data['token'];
      _currentUser = data['user'];
      
      await refreshAll();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 2. Logout Teacher
  void logout() {
    _token = null;
    _currentUser = null;
    _students = [];
    _tasks = [];
    _grades = [];
    _remarks = [];
    _notices = [];
    _dashboardStats = null;
    _errorMessage = null;
    notifyListeners();
  }

  // 3. Refresh All Data
  Future<void> refreshAll() async {
    if (!isAuthenticated) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch stats
      final stats = await _apiService.getDashboardStats(_token!);
      _dashboardStats = stats;
      
      // Fetch students list (roster)
      final studentList = await _apiService.getStudents(_token!);
      _students = studentList;
      
      // Fetch tasks list
      final taskList = await _apiService.getTasks(_token!);
      _tasks = taskList;
      
      // Fetch grades list
      final gradeList = await _apiService.getGrades(_token!);
      _grades = gradeList;
      
      // Fetch remarks list
      final remarkList = await _apiService.getBehaviorRemarks(_token!);
      _remarks = remarkList;
      
      // Fetch noticeboards
      final noticeList = await _apiService.getNotices(_token!);
      _notices = noticeList;
      
      // Refresh current user profile details
      final userData = await _apiService.getProfile(_token!);
      _currentUser = userData;
      
      // Fetch teachers list (if super admin)
      if (_currentUser != null && _currentUser!['is_super_admin'] == true) {
        final teacherList = await _apiService.getAllTeachers(_token!);
        _teachers = teacherList;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
    }
  }

  Future<void> fetchStudents() async {
    if (!isAuthenticated) return;
    _isLoading = true;
    notifyListeners();
    try {
      _students = await _apiService.getStudents(_token!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
    }
  }

  // 4. Register Student
  Future<bool> addStudent({
    required String name,
    required String rollNumber,
    required String grade,
    String? email,
    String? guardianName,
    String? guardianPhone,
  }) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.addStudent(
        _token!,
        name,
        rollNumber,
        grade,
        email,
        guardianName,
        guardianPhone,
      );
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 5. Delete Student
  Future<bool> deleteStudent(int studentId) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteStudent(_token!, studentId);
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 6. Assign Homework Task
  Future<bool> addTask({
    required int studentId,
    required String title,
    String? description,
    required String dueDate,
  }) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.addTask(_token!, studentId, title, description, dueDate);
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 7. Complete Task
  Future<bool> completeTask(int taskId) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.completeTask(_token!, taskId);
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // UPGRADED FEATURES
  // ==========================================

  // 8. Batch Save Attendance Register
  Future<bool> saveAttendanceBatch({
    required String dateString,
    required List<Map<String, dynamic>> records,
  }) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.saveAttendanceBatch(_token!, dateString, records);
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 9. Log Grade
  Future<bool> addGrade({
    required int studentId,
    required String examName,
    required String subject,
    required double marksObtained,
    required double maxMarks,
    String? remarks,
  }) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.addGrade(_token!, studentId, examName, subject, marksObtained, maxMarks, remarks);
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 10. Log Behavior Review Comment
  Future<bool> addBehaviorRemark({
    required int studentId,
    required String type,
    required String title,
    String? description,
  }) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.addBehaviorRemark(_token!, studentId, type, title, description);
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 11. Broadcast Announcement
  Future<bool> addNotice({
    required String title,
    required String content,
  }) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.addNotice(_token!, title, content);
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 12. Delete Notice
  Future<bool> deleteNotice(int noticeId) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteNotice(_token!, noticeId);
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 13. Fetch All Teachers (Super Admin only)
  Future<void> fetchTeachers() async {
    if (!isAuthenticated) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _teachers = await _apiService.getAllTeachers(_token!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
    }
  }

  // 14. Update Logged-In Teacher's Profile (with file paths)
  Future<bool> updateProfile({
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
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final userData = await _apiService.updateProfile(
        token: _token!,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        classAssigned: classAssigned,
        esicId: esicId,
        bankAccount: bankAccount,
        bankName: bankName,
        ifsc: ifsc,
        employeeId: employeeId,
        profilePicPath: profilePicPath,
        docPath: docPath,
      );
      _currentUser = userData;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 15. Update Teacher Profile as Admin (Super Admin only)
  Future<bool> updateTeacherByAdmin(int teacherId, Map<String, dynamic> data) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedUser = await _apiService.updateTeacherByAdmin(
        token: _token!,
        teacherId: teacherId,
        data: data,
      );
      // Update local teachers list
      final index = _teachers.indexWhere((t) => t['id'] == teacherId);
      if (index != -1) {
        _teachers[index] = updatedUser;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 16. Change Password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.changePassword(_token!, oldPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 17. Refresh User Profile
  Future<void> refreshUserProfile() async {
    if (!isAuthenticated) return;
    try {
      final userData = await _apiService.getProfile(_token!);
      _currentUser = userData;
      notifyListeners();
    } catch (e) {
      debugPrint("Error refreshing user profile: $e");
    }
  }

  // 18. Upload Document
  Future<bool> uploadDocument(String docPath, String name) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.uploadDocument(_token!, docPath, name);
      await refreshUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // 19. Delete Document
  Future<bool> deleteDocument(int docId) async {
    if (!isAuthenticated) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.deleteDocument(_token!, docId);
      await refreshUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }
}
