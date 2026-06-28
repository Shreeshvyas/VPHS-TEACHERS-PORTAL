import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddStudentSheet(BuildContext context) {
    final nameController = TextEditingController();
    final rollController = TextEditingController();
    final gradeController = TextEditingController();
    final emailController = TextEditingController();
    final guardianNameController = TextEditingController();
    final guardianPhoneController = TextEditingController();
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
                      'Register Student',
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
                
                // Name
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Student Name *', Icons.person_outline),
                  validator: (val) => val == null || val.isEmpty ? 'Enter student name' : null,
                ),
                const SizedBox(height: 12),

                // Roll Number & Grade
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: rollController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Roll No. *', Icons.pin_outlined),
                        validator: (val) => val == null || val.isEmpty ? 'Enter roll number' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: gradeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Class/Grade *', Icons.school_outlined),
                        validator: (val) => val == null || val.isEmpty ? 'Enter class/grade' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Email (Optional)', Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                // Guardian Details
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: guardianNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Guardian Name', Icons.family_restroom_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: guardianPhoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Guardian Phone', Icons.phone_outlined),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    final provider = Provider.of<PortalProvider>(context, listen: false);
                    final success = await provider.addStudent(
                      name: nameController.text.trim(),
                      rollNumber: rollController.text.trim(),
                      grade: gradeController.text.trim(),
                      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                      guardianName: guardianNameController.text.trim().isEmpty ? null : guardianNameController.text.trim(),
                      guardianPhone: guardianPhoneController.text.trim().isEmpty ? null : guardianPhoneController.text.trim(),
                    );

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${nameController.text.trim()} added successfully!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Failed to add student'),
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
                    'Add Student',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
              ],
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    
    // Filter roster
    final filteredStudents = provider.students.where((student) {
      final nameLower = student.name.toLowerCase();
      final rollLower = student.rollNumber.toLowerCase();
      final gradeLower = student.grade.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower) ||
          rollLower.contains(queryLower) ||
          gradeLower.contains(queryLower);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: TextStyle(color: provider.isDarkMode ? Colors.white : const Color(0xFF1F2937)),
              decoration: InputDecoration(
                hintText: 'Search by student name, roll no, grade...',
                hintStyle: GoogleFonts.outfit(color: provider.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: provider.isDarkMode ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
          ),

          // Students List Roster
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchStudents(),
              color: const Color(0xFF6366F1),
              child: filteredStudents.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        const Center(
                          child: Icon(Icons.school_outlined, size: 64, color: Color(0xFF262938)),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No students rostered yet'
                                : 'No students found matching "$_searchQuery"',
                            style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        final hasPending = student.pendingTaskCount > 0;

                        return Card(
                          color: Theme.of(context).colorScheme.surface,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(color: provider.isDarkMode ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailScreen(studentId: student.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: provider.isDarkMode ? const Color(0xFF1A1C26) : const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      student.name[0].toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: provider.isDarkMode ? Colors.white : const Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Roll: ${student.rollNumber}',
                                              style: GoogleFonts.outfit(
                                                color: provider.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Class: ${student.grade}',
                                              style: GoogleFonts.outfit(
                                                color: provider.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Badge for tasks count
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Tasks: ${student.taskCount}',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: hasPending
                                              ? const Color(0xFFF59E0B).withOpacity(0.08)
                                              : const Color(0xFF10B981).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: hasPending
                                                ? const Color(0xFFF59E0B).withOpacity(0.2)
                                                : const Color(0xFF10B981).withOpacity(0.2),
                                          ),
                                        ),
                                        child: Text(
                                          hasPending ? '${student.pendingTaskCount} pending' : 'Clean',
                                          style: GoogleFonts.outfit(
                                            color: hasPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentSheet(context),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

// Extension to card border styling pixel values on flutter
extension DoubleExtensions on double {
  double get val => this;
}
extension CardExtensions on Widget {
  Widget marginBottomPixelRatio(double value) => Padding(
        padding: EdgeInsets.only(bottom: value),
        child: this,
      );
}
