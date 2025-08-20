import 'dart:convert';
import 'package:fawran/services/api_service.dart';
import 'package:fawran/widgets/custome_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fawran/generated/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _validateAndSubmit() async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _oldPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool hasError = false;

    if (oldPassword.isEmpty) {
      _oldPasswordError = loc.oldPassRequired;
      hasError = true;
    }
    if (newPassword.isEmpty) {
      _newPasswordError = loc.newPassRequired;
      hasError = true;
    } else if (newPassword.length < 6) {
      _newPasswordError = loc.newPassMin;
      hasError = true;
    }
    if (confirmPassword.isEmpty) {
      _confirmPasswordError = loc.confirmPassRequired;
      hasError = true;
    } else if (confirmPassword != newPassword) {
      _confirmPasswordError = loc.confirmPassNotMatch;
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.successChange),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final responseBody = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody["message"] ?? loc.failChange),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
@override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  return Directionality(
    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Column(
          children: [
            // 🔹 Header
            Container(
              padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 12,
            ),
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
                      loc.changePass,
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

            // 🔹 Form Fields (scrollable)
            Expanded(
              child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                  CustomPasswordField(
  controller: _oldPasswordController,
  label: loc.oldPass,
  hint: isArabic ? "أدخل كلمة المرور القديمة" : "Enter old password",
  isArabic: isArabic,
  obscureText: _obscureOld,
  isPasswordVisible: !_obscureOld,
  onToggleVisibility: () {
    setState(() {
      _obscureOld = !_obscureOld;
    });
  },
  showError: _oldPasswordError != null,
  errorText: _oldPasswordError,
),
                    const SizedBox(height: 16),
                CustomPasswordField(
  controller: _newPasswordController,
  label: loc.newPass,
  hint: isArabic ? "أدخل كلمة المرور الجديدة" : "Enter new password",
  isArabic: isArabic,
  obscureText: _obscureOld,
  isPasswordVisible: !_obscureOld,
  onToggleVisibility: () {
    setState(() {
      _obscureOld = !_obscureOld;
    });
  },
  showError: _newPasswordError != null,
  errorText: _newPasswordError,
),
                    const SizedBox(height: 16),
             CustomPasswordField(
  controller: _confirmPasswordController,
  label: loc.confirmNewPassword,
  hint: isArabic ? "أدخل تاكيد كلمة المرور الجديدة" : "Enter new password confirmation",
  isArabic: isArabic,
  obscureText: _obscureOld,
  isPasswordVisible: !_obscureOld,
  onToggleVisibility: () {
    setState(() {
      _obscureOld = !_obscureOld;
    });
  },
  showError: _confirmPasswordError != null,
  errorText: _confirmPasswordError,
),
                  ],
                ),
              ),
            ),
            ),

            // 🔹 Bottom Buttons (fixed)
            SafeArea(
            top: false,
            child: Padding(
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
                        loc.cancel,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                        loc.saveChanges,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
  );
}

}
