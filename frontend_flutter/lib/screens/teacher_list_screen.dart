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
                style: GoogleFonts.outfit(color: Colors.white),
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
                  fillColor: const Color(0xFF12131A),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF262938)),
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
    );
  }
}
