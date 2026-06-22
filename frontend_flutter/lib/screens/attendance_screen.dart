import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<int, String> _statuses = {};
  Map<int, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeData() {
    final provider = Provider.of<PortalProvider>(context, listen: false);
    
    _statuses.clear();
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
    _remarksControllers.clear();

    final dateString = "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    for (var student in provider.students) {
      // Find if attendance is already marked for this date
      String status = 'PRESENT';
      String remarks = '';
      
      try {
        final existing = student.attendances.firstWhere(
          (a) => "${a.date.year.toString().padLeft(4, '0')}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}" == dateString,
        );
        status = existing.status;
        remarks = existing.remarks ?? '';
      } catch (_) {
        // No record found, default to PRESENT
      }

      _statuses[student.id] = status;
      _remarksControllers[student.id] = TextEditingController(text: remarks);
    }
  }

  void _save() async {
    final provider = Provider.of<PortalProvider>(context, listen: false);
    final dateString = "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    List<Map<String, dynamic>> records = [];
    _statuses.forEach((studentId, status) {
      records.add({
        'student': studentId,
        'status': status,
        'remarks': _remarksControllers[studentId]?.text.trim(),
      });
    });

    final success = await provider.saveAttendanceBatch(
      dateString: dateString,
      records: records,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance roster saved for $dateString!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save attendance'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);

    // Reinitialize if students roster updates
    if (_statuses.length != provider.students.length) {
      _initializeData();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12131A),
        title: Text(
          'Daily Attendance',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF6366F1)),
            onPressed: provider.students.isEmpty ? null : _save,
          )
        ],
      ),
      body: Column(
        children: [
          // Date Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF12131A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Register Date:',
                  style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                        _initializeData();
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6366F1)),
                  label: Text(
                    "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: provider.students.isEmpty
                ? Center(
                    child: Text(
                      'No students rostered to mark attendance',
                      style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: provider.students.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final student = provider.students[index];
                      final currentStatus = _statuses[student.id] ?? 'PRESENT';

                      return Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12131A),
                          border: Border.all(color: const Color(0xFF262938)),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Roll: ${student.rollNumber}  |  Class: ${student.grade}',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF9CA3AF),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Toggle options (P, A, L, LV)
                                _buildStatusToggle(student.id, currentStatus),
                              ],
                            ),
                            const SizedBox(height: 10),
                            
                            // Remarks input field
                            TextField(
                              controller: _remarksControllers[student.id],
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Remarks / Reason (e.g. sick leave)',
                                hintStyle: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                filled: true,
                                fillColor: const Color(0xFF1A1C26),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF262938)),
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
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: provider.students.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFF12131A),
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Save Attendance Register',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
    );
  }

  Widget _buildStatusToggle(int studentId, String currentStatus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleItem(studentId, 'PRESENT', 'P', const Color(0xFF10B981), currentStatus),
        const SizedBox(width: 4),
        _buildToggleItem(studentId, 'ABSENT', 'A', const Color(0xFFEF4444), currentStatus),
        const SizedBox(width: 4),
        _buildToggleItem(studentId, 'LATE', 'L', const Color(0xFFF59E0B), currentStatus),
        const SizedBox(width: 4),
        _buildToggleItem(studentId, 'LEAVE', 'LV', const Color(0xFF6366F1), currentStatus),
      ],
    );
  }

  Widget _buildToggleItem(
    int studentId,
    String value,
    String label,
    Color activeColor,
    String currentStatus,
  ) {
    final isSelected = currentStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statuses[studentId] = value;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFF1A1C26),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF262938),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
