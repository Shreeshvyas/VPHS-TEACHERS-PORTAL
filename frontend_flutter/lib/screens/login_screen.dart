import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController(text: ApiService.baseUrl);
  
  bool _obscurePassword = true;
  bool _showSettings = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = Provider.of<PortalProvider>(context, listen: false);
    
    // Save URL if configuration changed
    provider.updateApiUrl(_urlController.text.trim());

    final success = await provider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Authentication Failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    final isDark = provider.isDarkMode;

    final bgColor1 = isDark ? const Color(0xFF0A0B10) : const Color(0xFFF3F4F6);
    final bgColor2 = isDark ? const Color(0xFF12131A) : const Color(0xFFE5E7EB);
    final bgColor3 = isDark ? const Color(0xFF1A1C26) : const Color(0xFFD1D5DB);

    final cardBg = isDark ? const Color(0xFF12131A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262938) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final fieldFill = isDark ? const Color(0xFF1A1C26) : const Color(0xFFF9FAFB);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor1, bgColor2, bgColor3],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Brand Logo
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'VPHS Teachers Portal',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Log in to manage your classes',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          style: GoogleFonts.outfit(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: GoogleFonts.outfit(color: subtitleColor),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6366F1)),
                            filled: true,
                            fillColor: fieldFill,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1)),
                            ),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Please enter username' : null,
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.outfit(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: GoogleFonts.outfit(color: subtitleColor),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6366F1)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: subtitleColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: fieldFill,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1)),
                            ),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Please enter password' : null,
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: provider.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Expandable API settings
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showSettings = !_showSettings;
                            });
                          },
                          icon: Icon(
                            _showSettings ? Icons.arrow_drop_up : Icons.settings_outlined,
                            size: 16,
                            color: subtitleColor,
                          ),
                          label: Text(
                            _showSettings ? 'Hide API Connection' : 'API Connection Settings',
                            style: GoogleFonts.outfit(color: subtitleColor, fontSize: 12),
                          ),
                        ),
                        if (_showSettings) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _urlController,
                            style: GoogleFonts.outfit(color: textColor, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: 'API Base URL',
                              labelStyle: GoogleFonts.outfit(color: subtitleColor, fontSize: 12),
                              filled: true,
                              fillColor: fieldFill,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
