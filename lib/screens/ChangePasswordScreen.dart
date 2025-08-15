import 'dart:convert';

import 'package:fawran/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storage = FlutterSecureStorage();

  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _validateAndSubmit() async {
    setState(() {
      _oldPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool hasError = false;

    // Required checks
    if (oldPassword.isEmpty) {
      _oldPasswordError = "Old password is required";
      hasError = true;
    }
    if (newPassword.isEmpty) {
      _newPasswordError = "New password is required";
      hasError = true;
    } else if (newPassword.length < 6) {
      _newPasswordError = "Password must be at least 6 characters";
      hasError = true;
    }
    if (confirmPassword.isEmpty) {
      _confirmPasswordError = "Please confirm your password";
      hasError = true;
    } else if (confirmPassword != newPassword) {
      _confirmPasswordError = "Passwords do not match";
      hasError = true;
    }

    if (hasError) {
      setState(() {}); // Refresh UI with error messages
      return;
    }

    // Call API if no errors
    final phoneNumber = await _storage.read(key: 'phone_number') ?? '';
    final response = await ApiService.changePassword(
      phoneNumber: phoneNumber,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    if (response.statusCode == 200) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Password changed successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final responseBody = json.decode(response.body);
      // Show error from API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody["message"] ?? "Failed to change password"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0A2A66),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.orange),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "Change Password",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _passwordField(
                    controller: _oldPasswordController,
                    label: "Old Password",
                    obscureText: _obscureOld,
                    toggleObscure: () {
                      setState(() {
                        _obscureOld = !_obscureOld;
                      });
                    },
                    errorText: _oldPasswordError,
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _newPasswordController,
                    label: "New Password",
                    obscureText: _obscureNew,
                    toggleObscure: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                    errorText: _newPasswordError,
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _confirmPasswordController,
                    label: "Confirm Password",
                    obscureText: _obscureConfirm,
                    toggleObscure: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                    errorText: _confirmPasswordError,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2A66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Save Changes",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleObscure,
    String? errorText,
  }) {
    return SizedBox(
      height: errorText != null ? 72 : 52,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          errorText: errorText,
          prefix: Padding(
            padding: const EdgeInsets.fromLTRB(1, 8, 3, 1),
            child: SvgPicture.asset(
              'assets/images/lock.svg',
              color: const Color.fromRGBO(216, 219, 219, 1),
              width: 14,
              height: 14,
            ),
          ),
          suffixIcon: IconButton(
            icon: SvgPicture.asset(
              'assets/images/eye.svg',
              color: const Color.fromRGBO(216, 219, 219, 1),
              width: 14,
              height: 14,
            ),
            onPressed: toggleObscure,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
