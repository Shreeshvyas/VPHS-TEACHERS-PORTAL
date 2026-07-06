import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';
import 'teacher_detail_screen.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PortalProvider>(context, listen: false).fetchTeachers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    final teachersList = provider.teachers;
    final isDark = provider.isDarkMode;

    final filteredTeachers = teachersList.where((t) {
      final name = '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.toLowerCase();
      final username = (t['username'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1F2937)),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search teachers by name or username...',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF12131A) : const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
            ),

            Expanded(
              child: provider.isLoading && teachersList.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await provider.fetchTeachers();
                      },
                      color: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFF12131A),
                      child: filteredTeachers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline, color: Color(0xFF4B5563), size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No matching teachers found' : 'No teachers registered',
                                    style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
                                  )
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemCount: filteredTeachers.length,
                              itemBuilder: (context, index) {
                                final t = filteredTeachers[index];
                                final profile = t['profile'];
                                final fullName = '${t['first_name'] ?? t['username']} ${t['last_name'] ?? ''}'.trim();
                                final isSuper = t['is_super_admin'] == true;
                                final String? avatar = profile?['profile_picture'];
                                final String classAssigned = profile?['class_assigned'] ?? 'Not Assigned';
                                final int allowed = profile?['total_leaves'] ?? 15;
                                final int taken = profile?['leaves_taken'] ?? 0;
                                final int remaining = allowed - taken;

                                 return Card(
                                  color: Theme.of(context).colorScheme.surface,
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundImage: avatar != null ? NetworkImage(provider.getMediaUrl(avatar)) : null,
                                      backgroundColor: isDark ? const Color(0xFF1A1C26) : const Color(0xFFE5E7EB),
                                      child: avatar == null
                                          ? Text(
                                              fullName.substring(0, 1).toUpperCase(),
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                                            )
                                          : null,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            fullName,
                                            style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSuper)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Admin',
                                              style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Text(
                                          'Class Teacher: $classAssigned',
                                          style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Leaves: $remaining left / $allowed allowed',
                                          style: GoogleFonts.outfit(
                                            color: remaining <= 2 ? Colors.redAccent : const Color(0xFF9CA3AF),
                                            fontSize: 11,
                                            fontWeight: remaining <= 2 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF4B5563), size: 14),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TeacherDetailScreen(teacher: t),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: (provider.currentUser != null && provider.currentUser!['is_super_admin'] == true)
          ? FloatingActionButton(
              onPressed: () => _showAddTeacherDialog(context),
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddTeacherDialog(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context, listen: false);
    final isDark = provider.isDarkMode;
    
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final employeeIdController = TextEditingController();
    final classController = TextEditingController();
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF12131A) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.person_add, color: Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Text(
                    'Add New Teacher',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDialogField(
                          controller: usernameController,
                          label: 'Username *',
                          hint: 'e.g. sarah_c',
                          isDark: isDark,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        _buildDialogField(
                          controller: passwordController,
                          label: 'Password *',
                          hint: 'e.g. securepwd123',
                          isDark: isDark,
                          obscureText: true,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        _buildDialogField(
                          controller: firstNameController,
                          label: 'First Name *',
                          hint: 'e.g. Sarah',
                          isDark: isDark,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        _buildDialogField(
                          controller: lastNameController,
                          label: 'Last Name',
                          hint: 'e.g. Connor',
                          isDark: isDark,
                        ),
                        _buildDialogField(
                          controller: emailController,
                          label: 'Email Address *',
                          hint: 'e.g. sarah@email.com',
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        _buildDialogField(
                          controller: phoneController,
                          label: 'Phone Number',
                          hint: 'e.g. +91 98765 43210',
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildDialogField(
                          controller: employeeIdController,
                          label: 'Employee ID',
                          hint: 'e.g. EMP-1002',
                          isDark: isDark,
                        ),
                        _buildDialogField(
                          controller: classController,
                          label: 'Class Teacher Assignment',
                          hint: 'e.g. Class 10-A',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final data = {
                        'username': usernameController.text.trim(),
                        'password': passwordController.text.trim(),
                        'first_name': firstNameController.text.trim(),
                        'last_name': lastNameController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'employee_id': employeeIdController.text.trim(),
                        'class_assigned': classController.text.trim(),
                      };
                      
                      Navigator.pop(context); // Close dialog
                      
                      // Show loading overlay
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registering teacher account...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      final success = await provider.addTeacherByAdmin(data);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Teacher registered successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.errorMessage ?? 'Failed to register teacher.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Register',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1F2937), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF), fontSize: 13),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1C26) : const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
