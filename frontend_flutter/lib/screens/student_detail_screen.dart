import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';
import '../models/student.dart';

class StudentDetailScreen extends StatefulWidget {
  final int studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Homework Controllers
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();
  DateTime _taskDueDate = DateTime.now();

  // Grade Controllers
  final _gradeExamController = TextEditingController();
  final _gradeSubjectController = TextEditingController();
  final _gradeObtainedController = TextEditingController();
  final _gradeMaxController = TextEditingController(text: '100');
  final _gradeRemarksController = TextEditingController();

  // Behavior Controllers
  String _remarkType = 'POSITIVE';
  final _remarkTitleController = TextEditingController();
  final _remarkDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskTitleController.dispose();
    _taskDescController.dispose();
    _gradeExamController.dispose();
    _gradeSubjectController.dispose();
    _gradeObtainedController.dispose();
    _gradeMaxController.dispose();
    _gradeRemarksController.dispose();
    _remarkTitleController.dispose();
    _remarkDescController.dispose();
    super.dispose();
  }

  void _showAssignTaskSheet(BuildContext context, Student student) {
    final formKey = GlobalKey<FormState>();
    _taskDueDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assign Task to ${student.name}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taskTitleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Task Title *', Icons.title),
                    validator: (val) => val == null || val.isEmpty ? 'Enter task title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _taskDescController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Description', Icons.description),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: const Color(0xFF1A1C26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFF262938)),
                    ),
                    leading: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                    title: Text(
                      'Due Date: ${_taskDueDate.year}-${_taskDueDate.month.toString().padLeft(2, '0')}-${_taskDueDate.day.toString().padLeft(2, '0')}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    ),
                    trailing: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _taskDueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selectedDate != null) {
                        setModalState(() {
                          _taskDueDate = selectedDate;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final provider = Provider.of<PortalProvider>(context, listen: false);
                      final dateString = "${_taskDueDate.year.toString().padLeft(4, '0')}-${_taskDueDate.month.toString().padLeft(2, '0')}-${_taskDueDate.day.toString().padLeft(2, '0')}";

                      final success = await provider.addTask(
                        studentId: student.id,
                        title: _taskTitleController.text.trim(),
                        description: _taskDescController.text.trim().isEmpty ? null : _taskDescController.text.trim(),
                        dueDate: dateString,
                      );

                      if (success && context.mounted) {
                        _taskTitleController.clear();
                        _taskDescController.clear();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Homework task assigned!'), backgroundColor: Color(0xFF10B981)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Assign Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogGradeSheet(BuildContext context, Student student) {
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Log Exam Grade',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gradeExamController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Exam Name (e.g. Unit Test 1)', Icons.assessment_outlined),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gradeSubjectController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Subject Name (e.g. Mathematics)', Icons.subject),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gradeObtainedController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Marks Obtained', Icons.grade_outlined),
                        keyboardType: TextInputType.number,
                        validator: (val) => val == null || double.tryParse(val) == null ? 'Enter number' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _gradeMaxController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Maximum Marks', Icons.score_outlined),
                        keyboardType: TextInputType.number,
                        validator: (val) => val == null || double.tryParse(val) == null ? 'Enter number' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gradeRemarksController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Remarks / Feedback (Optional)', Icons.feedback_outlined),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final provider = Provider.of<PortalProvider>(context, listen: false);

                    final success = await provider.addGrade(
                      studentId: student.id,
                      examName: _gradeExamController.text.trim(),
                      subject: _gradeSubjectController.text.trim(),
                      marksObtained: double.parse(_gradeObtainedController.text),
                      maxMarks: double.parse(_gradeMaxController.text),
                      remarks: _gradeRemarksController.text.trim().isEmpty ? null : _gradeRemarksController.text.trim(),
                    );

                    if (success && context.mounted) {
                      _gradeExamController.clear();
                      _gradeSubjectController.clear();
                      _gradeObtainedController.clear();
                      _gradeRemarksController.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Grade logged successfully!'), backgroundColor: Color(0xFF10B981)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Log Grade Marks', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogRemarkSheet(BuildContext context, Student student) {
    final formKey = GlobalKey<FormState>();
    _remarkType = 'POSITIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Log Conduct Review',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Type select drop
                  Text('Remark Type *', style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C26),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF262938)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _remarkType,
                        dropdownColor: const Color(0xFF1A1C26),
                        style: const TextStyle(color: Colors.white),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'POSITIVE', child: Text('Positive Badge')),
                          DropdownMenuItem(value: 'WARNING', child: Text('Disciplinary Warning')),
                        ],
                        onChanged: (String? val) {
                          if (val != null) {
                            setModalState(() {
                              _remarkType = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _remarkTitleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Title (e.g. Star Student, Late Entry)', Icons.stars_outlined),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarkDescController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Behavioral Details', Icons.description_outlined),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final provider = Provider.of<PortalProvider>(context, listen: false);

                      final success = await provider.addBehaviorRemark(
                        studentId: student.id,
                        type: _remarkType,
                        title: _remarkTitleController.text.trim(),
                        description: _remarkDescController.text.trim().isEmpty ? null : _remarkDescController.text.trim(),
                      );

                      if (success && context.mounted) {
                        _remarkTitleController.clear();
                        _remarkDescController.clear();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Conduct review logged!'), backgroundColor: Color(0xFF10B981)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Log Conduct Remark', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 18),
      filled: true,
      fillColor: const Color(0xFF1A1C26),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF262938)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
      ),
    );
  }

  void _confirmDeleteStudent(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF12131A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: Color(0xFF262938)),
        ),
        title: Text('Delete Student?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove ${student.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<PortalProvider>(context, listen: false);
              final success = await provider.deleteStudent(student.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Student ${student.name} removed.'), backgroundColor: const Color(0xFFF59E0B)),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    
    Student? student;
    try {
      student = provider.students.firstWhere((s) => s.id == widget.studentId);
    } catch (_) {
      student = null;
    }

    if (student == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0B10),
        appBar: AppBar(title: const Text('Student Details')),
        body: const Center(child: Text('Student not found', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12131A),
        title: Text(
          student.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDeleteStudent(context, student!),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF6366F1),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Attendance'),
            Tab(icon: Icon(Icons.assessment_outlined, size: 18), text: 'Grades'),
            Tab(icon: Icon(Icons.stars_outlined, size: 18), text: 'Behavior'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, student),
                _buildAttendanceTab(context, student),
                _buildGradesTab(context, student),
                _buildRemarksTab(context, student),
              ],
            ),
    );
  }

  // 1. OVERVIEW TAB
  Widget _buildOverviewTab(BuildContext context, Student student) {
    final provider = Provider.of<PortalProvider>(context);
    final studentTasks = provider.tasks.where((t) => t.student == student.id).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF12131A),
              border: Border.all(color: const Color(0xFF262938)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoItem('Roll Number', student.rollNumber),
                const Divider(color: Color(0xFF262938), height: 16),
                _buildInfoItem('Class / Grade', student.grade),
                const Divider(color: Color(0xFF262938), height: 16),
                _buildInfoItem('Parent Email', student.email ?? 'Not provided'),
                const Divider(color: Color(0xFF262938), height: 16),
                _buildInfoItem('Guardian Name', student.guardianName ?? 'Not provided'),
                const Divider(color: Color(0xFF262938), height: 16),
                _buildInfoItem('Guardian Phone', student.guardianPhone ?? 'Not provided'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Homework list section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Homework Tasks (${studentTasks.length})', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _showAssignTaskSheet(context, student),
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF6366F1)),
                label: Text('Assign Task', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13)),
              )
            ],
          ),
          const SizedBox(height: 8),

          studentTasks.isEmpty
              ? _buildEmptyState('No homework tasks assigned')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: studentTasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = studentTasks[index];
                    final done = task.isCompleted;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12131A),
                        border: Border.all(color: done ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF262938)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    color: done ? const Color(0xFF9CA3AF) : Colors.white,
                                    decoration: done ? TextDecoration.lineThrough : null,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Due: ${task.dueDate.year}-${task.dueDate.month.toString().padLeft(2, '0')}-${task.dueDate.day.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (!done)
                            ElevatedButton(
                              onPressed: () => provider.completeTask(task.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              child: Text('Complete', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          else
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  // 2. ATTENDANCE TAB
  Widget _buildAttendanceTab(BuildContext context, Student student) {
    final attendances = student.attendances;

    // Calculate rates
    final total = attendances.length;
    final present = attendances.where((a) => a.status == 'PRESENT').length;
    final absent = attendances.where((a) => a.status == 'ABSENT').length;
    final late = attendances.where((a) => a.status == 'LATE').length;
    final leave = attendances.where((a) => a.status == 'LEAVE').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance summary cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF12131A),
              border: Border.all(color: const Color(0xFF262938)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${student.attendancePercentage.round()}%',
                        style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                      ),
                      Text('Attendance Rate', style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13)),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF262938), height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatIndicator('Marked', total.toString(), Colors.white),
                    _buildStatIndicator('Present', present.toString(), const Color(0xFF10B981)),
                    _buildStatIndicator('Absent', absent.toString(), const Color(0xFFEF4444)),
                    _buildStatIndicator('Late', late.toString(), const Color(0xFFF59E0B)),
                    _buildStatIndicator('Leave', leave.toString(), const Color(0xFF6366F1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Attendance History', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          attendances.isEmpty
              ? _buildEmptyState('No attendance logs recorded yet')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: attendances.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final att = attendances[index];
                    Color statusColor = const Color(0xFF10B981);
                    if (att.status == 'ABSENT') statusColor = const Color(0xFFEF4444);
                    if (att.status == 'LATE') statusColor = const Color(0xFFF59E0B);
                    if (att.status == 'LEAVE') statusColor = const Color(0xFF6366F1);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12131A),
                        border: Border.all(color: const Color(0xFF262938)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${att.date.year}-${att.date.month.toString().padLeft(2, '0')}-${att.date.day.toString().padLeft(2, '0')}",
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              if (att.remarks != null && att.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  att.remarks!,
                                  style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 12),
                                )
                              ]
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.08),
                              border: Border.all(color: statusColor.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              att.status,
                              style: GoogleFonts.outfit(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  // 3. GRADES TAB
  Widget _buildGradesTab(BuildContext context, Student student) {
    final grades = student.grades;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF12131A),
              border: Border.all(color: const Color(0xFF262938)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    '${student.averageGrade.round()}%',
                    style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
                  ),
                  Text('Average Grade Score', style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Academic Grades (${grades.length})', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _showLogGradeSheet(context, student),
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF6366F1)),
                label: Text('Log Grade', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13)),
              )
            ],
          ),
          const SizedBox(height: 8),

          grades.isEmpty
              ? _buildEmptyState('No exam grades logged yet')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: grades.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final grade = grades[index];
                    final isFailed = grade.percentage < 50;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12131A),
                        border: Border.all(color: const Color(0xFF262938)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  grade.examName,
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Subject: ${grade.subject}  |  Marks: ${grade.marksObtained}/${grade.maxMarks.round()}',
                                  style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 12),
                                ),
                                if (grade.remarks != null && grade.remarks!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    grade.remarks!,
                                    style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 11),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFailed ? const Color(0xFFEF4444).withOpacity(0.08) : const Color(0xFF10B981).withOpacity(0.08),
                              border: Border.all(color: isFailed ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${grade.percentage.round()}% (${grade.gradeLetter})',
                              style: GoogleFonts.outfit(
                                color: isFailed ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  // 4. BEHAVIOR REMARKS TAB
  Widget _buildRemarksTab(BuildContext context, Student student) {
    final remarks = student.behaviorRemarks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Conduct & Review logs (${remarks.length})', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _showLogRemarkSheet(context, student),
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF6366F1)),
                label: Text('Log Remark', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13)),
              )
            ],
          ),
          const SizedBox(height: 8),

          remarks.isEmpty
              ? _buildEmptyState('No behavioral reviews logged yet')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: remarks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final remark = remarks[index];
                    final isPositive = remark.isPositive;
                    final badgeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12131A),
                        border: Border.all(color: const Color(0xFF262938)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isPositive ? Icons.workspace_premium : Icons.warning_amber_rounded,
                            color: badgeColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      remark.title,
                                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${remark.createdAt.year}-${remark.createdAt.month.toString().padLeft(2, '0')}-${remark.createdAt.day.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 11),
                                    ),
                                  ],
                                ),
                                if (remark.description != null && remark.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    remark.description!,
                                    style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  // Helpers widgets
  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14)),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFF12131A),
        border: Border.all(color: const Color(0xFF262938)),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(text, style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 13)),
    );
  }

  Widget _buildStatIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 10)),
      ],
    );
  }
}
