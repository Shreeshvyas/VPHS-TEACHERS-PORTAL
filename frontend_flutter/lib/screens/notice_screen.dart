import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';
import '../models/notice.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PortalProvider>(context, listen: false).refreshAll();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showAddNoticeSheet(BuildContext context) {
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
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Broadcast Notice',
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
              
              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Notice Title *'),
                validator: (val) => val == null || val.isEmpty ? 'Enter notice title' : null,
              ),
              const SizedBox(height: 12),

              // Content
              TextFormField(
                controller: _contentController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Announcement Content *'),
                maxLines: 5,
                validator: (val) => val == null || val.isEmpty ? 'Enter announcement details' : null,
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  
                  final provider = Provider.of<PortalProvider>(context, listen: false);
                  final success = await provider.addNotice(
                    title: _titleController.text.trim(),
                    content: _contentController.text.trim(),
                  );

                  if (success && context.mounted) {
                    _titleController.clear();
                    _contentController.clear();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notice broadcasted successfully!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage ?? 'Failed to post notice'),
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
                  'Broadcast Notice',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
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

  void _confirmDeleteNotice(BuildContext context, Notice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF12131A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: Color(0xFF262938)),
        ),
        title: Text(
          'Delete Announcement?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove "${notice.title}"?',
          style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              final provider = Provider.of<PortalProvider>(context, listen: false);
              final success = await provider.deleteNotice(notice.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notice deleted.'),
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                );
              }
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);

    final isDark = provider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Noticeboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshAll(),
        color: const Color(0xFF6366F1),
        child: provider.notices.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Center(
                    child: Icon(Icons.campaign_outlined, size: 64, color: Color(0xFF262938)),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No notices broadcasted yet',
                      style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 16),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: provider.notices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final notice = provider.notices[index];

                  return Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notice.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              onPressed: () => _confirmDeleteNotice(context, notice),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.account_circle, size: 12, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(
                              'By: ${notice.teacherName}',
                              style: GoogleFonts.outfit(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF4B5563), fontSize: 11),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.schedule, size: 12, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(
                              '${notice.createdAt.year}-${notice.createdAt.month.toString().padLeft(2, '0')}-${notice.createdAt.day.toString().padLeft(2, '0')} ${notice.createdAt.hour.toString().padLeft(2, '0')}:${notice.createdAt.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.outfit(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF4B5563), fontSize: 11),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
                        ),
                        Text(
                          notice.content,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoticeSheet(context),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.campaign, color: Colors.white),
      ),
    );
  }
}
