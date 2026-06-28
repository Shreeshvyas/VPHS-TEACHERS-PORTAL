import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';
import 'login_screen.dart';
import 'student_list_screen.dart';
import 'task_list_screen.dart';
import 'attendance_screen.dart';
import 'gradebook_screen.dart';
import 'notice_screen.dart';
import 'teacher_list_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PortalProvider>(context, listen: false).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    final user = provider.currentUser;
    final bool isSuperAdmin = user?['is_super_admin'] == true;

    final List<Widget> screens = isSuperAdmin
        ? [
            const HomeDashboardView(),
            const TeacherListScreen(),
            const StudentListScreen(),
          ]
        : [
            const HomeDashboardView(),
            const StudentListScreen(),
            const TaskListScreen(),
            const ProfileScreen(),
          ];

    int currentIndex = _selectedIndex;
    if (currentIndex >= screens.length) {
      currentIndex = 0;
    }

    String title = 'Portal';
    if (isSuperAdmin) {
      if (currentIndex == 0) title = 'Super Admin Dashboard';
      if (currentIndex == 1) title = 'Teachers Directory';
      if (currentIndex == 2) title = 'All Students';
    } else {
      if (currentIndex == 0) title = 'Teacher Dashboard';
      if (currentIndex == 1) title = 'Student Roster';
      if (currentIndex == 2) title = 'Tasks & Assignments';
      if (currentIndex == 3) title = 'My Profile';
    }

    String name = user?['first_name'] != null && user!['first_name'].toString().isNotEmpty
        ? '${user['first_name']} ${user['last_name'] ?? ''}'.trim()
        : (user?['username'] ?? 'User');
    String subtitle = isSuperAdmin ? '$name  |  Super Admin' : '$name  |  School Teacher';

    final isDark = provider.isDarkMode;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            if (user != null && currentIndex == 0)
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              provider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: const Color(0xFF6366F1),
            ),
            onPressed: () {
              provider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
            onPressed: () async {
              await provider.refreshAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Portal data refreshed'), duration: Duration(seconds: 1)),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              provider.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF262938), width: 1),
        ),
      ),
      body: provider.isLoading && provider.students.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(),
          type: BottomNavigationBarType.fixed,
          items: isSuperAdmin
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_alt_outlined),
                    activeIcon: Icon(Icons.people_alt),
                    label: 'Teachers',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.school_outlined),
                    activeIcon: Icon(Icons.school),
                    label: 'Students',
                  ),
                ]
              : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.school_outlined),
                    activeIcon: Icon(Icons.school),
                    label: 'Students',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt_outlined),
                    activeIcon: Icon(Icons.list_alt),
                    label: 'Tasks',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
        ),
      ),
    );
  }
}

// Inner view for Dashboard Tab
class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    final stats = provider.dashboardStats;
    final isDark = provider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final borderColor = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);
    final cardBg = Theme.of(context).colorScheme.surface;

    if (stats == null) {
      return Center(child: Text('No stats available', style: TextStyle(color: textColor)));
    }

    final int totalStudents = stats['total_students'] ?? 0;
    final double attendanceRate = (stats['average_attendance'] as num? ?? 100.0).toDouble();
    final double gradeAverage = (stats['average_grade'] as num? ?? 0.0).toDouble();
    final int pendingTasks = stats['pending_tasks'] ?? 0;
    final List recentNotices = stats['recent_notices'] ?? [];
    final List recentRemarks = stats['recent_remarks'] ?? [];

    return RefreshIndicator(
      onRefresh: () => provider.refreshAll(),
      color: const Color(0xFF6366F1),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row of Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Students',
                    value: totalStudents.toString(),
                    icon: Icons.people_outline,
                    iconColor: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Attendance',
                    value: '$attendanceRate%',
                    icon: Icons.calendar_month_outlined,
                    iconColor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Class Average',
                    value: '$gradeAverage%',
                    icon: Icons.assessment_outlined,
                    iconColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pending Tasks',
                    value: pendingTasks.toString(),
                    icon: Icons.assignment_late_outlined,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Shortcuts Grid
            Text(
              'Quick Administrative Tools',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            builderCurrentUserShortcut(context, provider),
            const SizedBox(height: 24),

            // Circular notices feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Noticeboard Announcements',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeScreen()));
                  },
                  child: Text('View All', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            recentNotices.isEmpty
                ? _buildEmptyFeed(context, 'No class circular announcements')
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentNotices.length > 2 ? 2 : recentNotices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = recentNotices[index];
                      return Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: cardBg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['content'],
                              style: GoogleFonts.outfit(color: subtitleColor, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),

            // Behavior Logs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Student Conduct Log',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),

            recentRemarks.isEmpty
                ? _buildEmptyFeed(context, 'No conduct feedback logged recently')
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentRemarks.length > 3 ? 3 : recentRemarks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = recentRemarks[index];
                      final isPositive = item['type'] == 'POSITIVE';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: cardBg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPositive ? Icons.workspace_premium : Icons.warning_amber_rounded,
                              color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['student_name'] ?? 'Student',
                                    style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    item['remark'] ?? '',
                                    style: GoogleFonts.outfit(color: subtitleColor, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: subtitleColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildShortcutButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF4B5563);

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: labelColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget builderCurrentUserShortcut(BuildContext context, PortalProvider provider) {
    final bool isSuperAdmin = provider.currentUser?['is_super_admin'] == true;
    if (isSuperAdmin) {
      return Row(
        children: [
          Expanded(
            child: _buildShortcutButton(
              context,
              label: 'Broadcast\nAnnouncement',
              icon: Icons.campaign_outlined,
              color: const Color(0xFF6366F1),
              screen: const NoticeScreen(),
            ),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          const SizedBox(width: 8),
          const Spacer(),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildShortcutButton(
              context,
              label: 'Mark Daily\nAttendance',
              icon: Icons.calendar_today,
              color: const Color(0xFF10B981),
              screen: const AttendanceScreen(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildShortcutButton(
              context,
              label: 'Manage class\nGradebook',
              icon: Icons.book_outlined,
              color: const Color(0xFF3B82F6),
              screen: const GradebookScreen(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildShortcutButton(
              context,
              label: 'Broadcast\nAnnouncement',
              icon: Icons.campaign_outlined,
              color: const Color(0xFF6366F1),
              screen: const NoticeScreen(),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildEmptyFeed(BuildContext context, String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);
    final subtitleColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(msg, style: GoogleFonts.outfit(color: subtitleColor, fontSize: 13)),
    );
  }
}
