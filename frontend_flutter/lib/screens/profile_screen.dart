import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/portal_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _classController;
  late TextEditingController _employeeIdController;
  late TextEditingController _esicController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankNameController;
  late TextEditingController _ifscController;

  String? _profilePicPath;
  String? _docPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PortalProvider>(context, listen: false);
    final user = provider.currentUser;
    final profile = user?['profile'];

    _firstNameController = TextEditingController(text: user?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: user?['last_name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    
    _phoneController = TextEditingController(text: profile?['phone'] ?? '');
    _classController = TextEditingController(text: profile?['class_assigned'] ?? '');
    _employeeIdController = TextEditingController(text: profile?['employee_id'] ?? '');
    _esicController = TextEditingController(text: profile?['esic_id'] ?? '');
    _bankAccountController = TextEditingController(text: profile?['bank_account_number'] ?? '');
    _bankNameController = TextEditingController(text: profile?['bank_name'] ?? '');
    _ifscController = TextEditingController(text: profile?['ifsc_code'] ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _classController.dispose();
    _employeeIdController.dispose();
    _esicController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          if (isProfile) {
            _profilePicPath = image.path;
          } else {
            _docPath = image.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e')),
        );
      }
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PortalProvider>(context, listen: false);
    
    final success = await provider.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      classAssigned: _classController.text.trim(),
      esicId: _esicController.text.trim(),
      bankAccount: _bankAccountController.text.trim(),
      bankName: _bankNameController.text.trim(),
      ifsc: _ifscController.text.trim(),
      employeeId: _employeeIdController.text.trim(),
      profilePicPath: _profilePicPath,
      docPath: _docPath,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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

  void _uploadMultipleDocPicker() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;
      
      final nameController = TextEditingController(text: file.name);
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          final isDark = Provider.of<PortalProvider>(context).isDarkMode;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF12131A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
            ),
            title: Text(
              'Upload Document',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File selected: ${file.name}',
                  style: GoogleFonts.outfit(fontSize: 13, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1F2937)),
                  decoration: InputDecoration(
                    labelText: 'Document Title',
                    labelStyle: GoogleFonts.outfit(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: () async {
                  final provider = Provider.of<PortalProvider>(context, listen: false);
                  Navigator.pop(context);
                  final success = await provider.uploadDocument(file.path, nameController.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Document uploaded successfully!' : 'Upload failed'),
                        backgroundColor: success ? Colors.green : Colors.redAccent,
                      ),
                    );
                  }
                },
                child: Text('Upload', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  void _changePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Provider.of<PortalProvider>(context).isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF12131A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB)),
          ),
          title: Text(
            'Change Password',
            style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1F2937), fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: dialogKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: true,
                    style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: GoogleFonts.outfit(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Please enter current password' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: GoogleFonts.outfit(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
                    ),
                    validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: GoogleFonts.outfit(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
                    ),
                    validator: (val) {
                      if (val != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              onPressed: () async {
                if (!dialogKey.currentState!.validate()) return;
                
                final provider = Provider.of<PortalProvider>(context, listen: false);
                final success = await provider.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password updated successfully!' : (provider.errorMessage ?? 'Failed to update password')),
                      backgroundColor: success ? Colors.green : Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text('Update', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    final user = provider.currentUser;
    final profile = user?['profile'];

    final String? serverProfilePic = profile?['profile_picture'];
    final String? serverDoc = profile?['document_file'];

    final isDark = provider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0A0B10) : const Color(0xFFF3F4F6);
    final cardBg = isDark ? const Color(0xFF12131A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final fieldFill = isDark ? const Color(0xFF1A1C26) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Leaves Widget
                _buildLeavesCard(profile),
                const SizedBox(height: 24),

                // Form panel
                Card(
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(color: borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Details',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Avatar Picker
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: fieldFill,
                                backgroundImage: _profilePicPath != null
                                    ? FileImage(File(_profilePicPath!))
                                    : (serverProfilePic != null
                                        ? NetworkImage(serverProfilePic)
                                        : null) as ImageProvider?,
                                child: _profilePicPath == null && serverProfilePic == null
                                    ? Text(
                                        (user?['username'] ?? 'T').substring(0, 1).toUpperCase(),
                                        style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () => _pickImage(true),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6366F1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildTextField('First Name', _firstNameController),
                        _buildTextField('Last Name', _lastNameController),
                        _buildTextField('Employee ID (School Code)', _employeeIdController),
                        _buildTextField('Email Address', _emailController),
                        _buildTextField('Phone Number', _phoneController),
                        _buildTextField('Assigned Class (e.g. Class 10-A)', _classController),
                        _buildTextField('ESIC ID', _esicController),

                        const SizedBox(height: 16),
                        Text(
                          'Bank Details',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Bank Name', _bankNameController),
                        _buildTextField('Account Number', _bankAccountController),
                        _buildTextField('IFSC Code', _ifscController),

                        const SizedBox(height: 16),
                        Text(
                          'Primary Verification Proof',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(false),
                              icon: const Icon(Icons.upload_file, color: Colors.white),
                              label: Text('Select Doc', style: GoogleFonts.outfit(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _docPath != null
                                    ? 'Selected: ${_docPath!.split('/').last}'
                                    : (serverDoc != null ? 'Verification Document uploaded' : 'No document uploaded'),
                                style: GoogleFonts.outfit(color: subtitleColor, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: provider.isLoading ? null : _saveProfile,
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
                                    'Save Profile Settings',
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Change Password Section
                Card(
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(color: borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Settings',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Keep your account credentials secure. You can update your portal login password here.',
                          style: GoogleFonts.outfit(fontSize: 13, color: subtitleColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _changePasswordDialog,
                          icon: const Icon(Icons.lock_reset, color: Colors.white),
                          label: Text('Change Password', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Documents Section
                _buildDocumentsSection(profile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(Map<String, dynamic>? profile) {
    final provider = Provider.of<PortalProvider>(context);
    final isDark = provider.isDarkMode;
    final cardBg = isDark ? const Color(0xFF12131A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);

    final List<dynamic> documents = profile?['documents'] ?? [];

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Documents',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadMultipleDocPicker,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: Text('Upload', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (documents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No uploaded documents. Upload certificates or IDs here.',
                  style: GoogleFonts.outfit(color: subtitleColor, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  final docName = doc['name'] ?? 'Document #${doc['id']}';
                  final docUrl = doc['file'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1C26) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.file_present, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            docName,
                            style: GoogleFonts.outfit(color: textColor, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (docUrl != null)
                          IconButton(
                            icon: const Icon(Icons.download, size: 18, color: Color(0xFF6366F1)),
                            onPressed: () => _launchUrl(docUrl),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          onPressed: () async {
                            final success = await provider.deleteDocument(doc['id']);
                            if (mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Document deleted successfully!')),
                              );
                            }
                          },
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

  Widget _buildTextField(String label, TextEditingController controller) {
    final isDark = Provider.of<PortalProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final fill = isDark ? const Color(0xFF1A1C26) : const Color(0xFFF9FAFB);
    final border = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.outfit(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: labelColor),
          filled: true,
          fillColor: fill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1)),
          ),
        ),
      ),
    );
  }

  Widget _buildLeavesCard(Map<String, dynamic>? profile) {
    final int allowed = profile?['total_leaves'] ?? 15;
    final int taken = profile?['leaves_taken'] ?? 0;
    final int remaining = allowed - taken;

    final isDark = Provider.of<PortalProvider>(context).isDarkMode;
    final cardBg = isDark ? const Color(0xFF12131A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leaves Counter',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLeafMetric('Total Quota', allowed.toString(), const Color(0xFF6366F1)),
                const SizedBox(width: 12),
                _buildLeafMetric('Taken', taken.toString(), Colors.amber),
                const SizedBox(width: 12),
                _buildLeafMetric('Remaining', remaining.toString(), Colors.green),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLeafMetric(String label, String value, Color color) {
    final isDark = Provider.of<PortalProvider>(context).isDarkMode;
    final fill = isDark ? const Color(0xFF1A1C26) : const Color(0xFFF9FAFB);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 11, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
