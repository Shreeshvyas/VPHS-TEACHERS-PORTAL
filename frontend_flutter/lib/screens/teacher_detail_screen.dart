import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/portal_provider.dart';

class TeacherDetailScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  const TeacherDetailScreen({super.key, required this.teacher});

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _classController;
  late TextEditingController _totalLeavesController;
  late TextEditingController _leavesTakenController;

  @override
  void initState() {
    super.initState();
    final profile = widget.teacher['profile'];
    _classController = TextEditingController(text: profile?['class_assigned'] ?? '');
    _totalLeavesController = TextEditingController(text: (profile?['total_leaves'] ?? 15).toString());
    _leavesTakenController = TextEditingController(text: (profile?['leaves_taken'] ?? 0).toString());
  }

  @override
  void dispose() {
    _classController.dispose();
    _totalLeavesController.dispose();
    _leavesTakenController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open document: $e')),
        );
      }
    }
  }

  void _updateTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PortalProvider>(context, listen: false);
    final int? total = int.tryParse(_totalLeavesController.text);
    final int? taken = int.tryParse(_leavesTakenController.text);

    if (total == null || taken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric leaves values')),
      );
      return;
    }

    final success = await provider.updateTeacherByAdmin(
      widget.teacher['id'],
      {
        'class_assigned': _classController.text.trim(),
        'total_leaves': total,
        'leaves_taken': taken,
      },
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher settings updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update settings'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    final profile = widget.teacher['profile'];
    final fullName = '${widget.teacher['first_name'] ?? widget.teacher['username']} ${widget.teacher['last_name'] ?? ''}'.trim();
    final String? avatar = profile?['profile_picture'];
    final String? docUrl = profile?['document_file'];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12131A),
        elevation: 0,
        title: Text(
          'Manage: ${widget.teacher['username']}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const Border(bottom: BorderSide(color: Color(0xFF262938), width: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Teacher Header
              Card(
                color: const Color(0xFF12131A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF262938)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        backgroundColor: const Color(0xFF1A1C26),
                        child: avatar == null
                            ? Text(
                                fullName.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${widget.teacher['username']}  |  ${widget.teacher['email'] ?? 'No email'}',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9CA3AF)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${profile?['phone'] ?? 'None'}',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bank Details & ESIC
              Card(
                color: const Color(0xFF12131A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF262938)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employment & Bank Details',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('ESIC ID', profile?['esic_id'] ?? 'Not Provided'),
                      _buildDetailRow('Bank Name', profile?['bank_name'] ?? 'Not Provided'),
                      _buildDetailRow('Account Number', profile?['bank_account_number'] ?? 'Not Provided'),
                      _buildDetailRow('IFSC Code', profile?['ifsc_code'] ?? 'Not Provided'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Document Check
              Card(
                color: const Color(0xFF12131A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF262938)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification Document',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
                      ),
                      const SizedBox(height: 12),
                      docUrl != null
                          ? Row(
                              children: [
                                const Icon(Icons.file_present, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Teacher ID/Degree Document uploaded.',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download, color: Color(0xFF6366F1)),
                                  onPressed: () => _launchUrl(docUrl),
                                )
                              ],
                            )
                          : Text(
                              'No identity proof document uploaded yet.',
                              style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 12, fontStyle: FontStyle.italic),
                            )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Administrative Controls
              Card(
                color: const Color(0xFF12131A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: Color(0xFF262938)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrative Settings',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField('Assigned Class (e.g. Class 10-A)', _classController),
                      
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Total Leaves', _totalLeavesController, isNumeric: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Leaves Taken', _leavesTakenController, isNumeric: true)),
                        ],
                      ),

                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: provider.isLoading ? null : _updateTeacher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Center(
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Save Admin Configuration',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13)),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF1A1C26),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF262938)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1)),
          ),
        ),
        validator: (val) {
          if (val == null || val.isEmpty) return 'Please enter value';
          return null;
        },
      ),
    );
  }
}
