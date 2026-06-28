import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/portal_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    final user = provider.currentUser;
    final profile = user?['profile'];

    final String? serverProfilePic = profile?['profile_picture'];
    final String? serverDoc = profile?['document_file'];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
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
                                backgroundColor: const Color(0xFF1A1C26),
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
                          'Verification Document',
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
                                backgroundColor: const Color(0xFF262938),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _docPath != null
                                    ? 'Selected: ${_docPath!.split('/').last}'
                                    : (serverDoc != null ? 'Verification Document uploaded' : 'No document uploaded'),
                                style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
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
      ),
    );
  }

  Widget _buildLeavesCard(Map<String, dynamic>? profile) {
    final int allowed = profile?['total_leaves'] ?? 15;
    final int taken = profile?['leaves_taken'] ?? 0;
    final int remaining = allowed - taken;

    return Card(
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
              'Leaves Counter',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C26),
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
              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
