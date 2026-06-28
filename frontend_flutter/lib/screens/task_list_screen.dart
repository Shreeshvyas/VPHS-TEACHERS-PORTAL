import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';
import '../models/student.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  Student? _selectedStudent;
  DateTime _dueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    
    _dueDate = DateTime.now();
    _selectedStudent = provider.students.isNotEmpty ? provider.students[0] : null;

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
                        'Assign New Task',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Select Student Dropdown
                  Text(
                    'Assign to Student *',
                    style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C26),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF262938)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Student>(
                        value: _selectedStudent,
                        dropdownColor: const Color(0xFF1A1C26),
                        style: const TextStyle(color: Colors.white),
                        isExpanded: true,
                        hint: const Text('Select a Student', style: TextStyle(color: Color(0xFF6B7280))),
                        items: provider.students.map((student) {
                          return DropdownMenuItem<Student>(
                            value: student,
                            child: Text('${student.name} (${student.grade})'),
                          );
                        }).toList(),
                        onChanged: (Student? val) {
                          setModalState(() {
                            _selectedStudent = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Title
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Task Title *', Icons.title),
                    validator: (val) => val == null || val.isEmpty ? 'Enter task title' : null,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Description', Icons.description),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Due Date Selector
                  ListTile(
                    tileColor: const Color(0xFF1A1C26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFF262938)),
                    ),
                    leading: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                    title: Text(
                      'Due Date: ${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    ),
                    trailing: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selectedDate != null) {
                        setModalState(() {
                          _dueDate = selectedDate;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (_selectedStudent == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a student')),
                        );
                        return;
                      }
                      
                      final dateString = "${_dueDate.year.toString().padLeft(4, '0')}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}";

                      final success = await provider.addTask(
                        studentId: _selectedStudent!.id,
                        title: _titleController.text.trim(),
                        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                        dueDate: dateString,
                      );

                      if (success && context.mounted) {
                        _titleController.clear();
                        _descController.clear();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task assigned to ${_selectedStudent!.name}!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.errorMessage ?? 'Failed to assign task'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Assign Task',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    final tasks = provider.tasks;

    final pendingTasks = tasks.where((t) => t.status == 'PENDING').toList();
    final completedTasks = tasks.where((t) => t.status == 'COMPLETED').toList();

    final isDark = provider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Tab bar indicators
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              indicatorColor: const Color(0xFF6366F1),
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14),
              tabs: [
                Tab(text: 'All (${tasks.length})'),
                Tab(text: 'Pending (${pendingTasks.length})'),
                Tab(text: 'Completed (${completedTasks.length})'),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksList(context, tasks, provider),
                _buildTasksList(context, pendingTasks, provider),
                _buildTasksList(context, completedTasks, provider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: provider.students.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context),
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add_task, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTasksList(BuildContext context, List<Task> taskList, PortalProvider provider) {
    final isDark = provider.isDarkMode;
    if (taskList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.refreshAll(),
        color: const Color(0xFF6366F1),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const Center(
              child: Icon(Icons.list_alt_outlined, size: 64, color: Color(0xFF262938)),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No tasks to display',
                style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshAll(),
      color: const Color(0xFF6366F1),
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: taskList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = taskList[index];
          final isCompleted = task.isCompleted;

          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isCompleted ? const Color(0xFF10B981).withOpacity(0.15) : (isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1A1C26) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.studentGrade,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Due: ${task.dueDate.year}-${task.dueDate.month.toString().padLeft(2, '0')}-${task.dueDate.day.toString().padLeft(2, '0')}',
                            style: GoogleFonts.outfit(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF), fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        task.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? const Color(0xFF9CA3AF) : (isDark ? Colors.white : const Color(0xFF1F2937)),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      
                      // Student name footer
                      Row(
                        children: [
                          const Icon(Icons.account_circle_outlined, size: 14, color: Color(0xFF6366F1)),
                          const SizedBox(width: 6),
                          Text(
                            '${task.studentName} (Roll: ${task.studentRoll})',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Done / Complete Actions
                if (!isCompleted)
                  ElevatedButton(
                    onPressed: () async {
                      final success = await provider.completeTask(task.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task "${task.title}" completed!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Complete',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Done',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}
