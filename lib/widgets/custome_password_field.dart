import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isArabic;
  final bool obscureText;
  final bool showError;
  final String? errorText;
  final VoidCallback onToggleVisibility;
  final bool isPasswordVisible;

  const CustomPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.isArabic,
    required this.obscureText,
    required this.showError,
    this.errorText,
    required this.onToggleVisibility,
    required this.isPasswordVisible,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,

        // 🔹 Lock icon placement RTL/LTR
        prefixIcon: isArabic
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SvgPicture.asset(
                      'assets/icons/lock.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Colors.grey.shade400,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(15.0),
                child: SvgPicture.asset(
                  'assets/icons/lock.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade400,
                    BlendMode.srcIn,
                  ),
                ),
              ),

        // 🔹 Eye / Eye-slash icon
        suffixIcon: IconButton(
          icon: Padding(
            padding: const EdgeInsets.all(2.0),
            child: SvgPicture.asset(
              isPasswordVisible
                  ? 'assets/icons/eye-regular-full.svg'
                  : 'assets/icons/eye-slash-regular-full.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                Colors.grey.shade400,
                BlendMode.srcIn,
              ),
            ),
          ),
          onPressed: onToggleVisibility,
        ),

        // 🔹 Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4A90E2),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),

        // 🔹 Text styles
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFD8DBDB),
          fontSize: 16,
          fontWeight: FontWeight.w300,
          fontFamily: 'poppins',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        // 🔹 Error handling
        errorText: showError ? errorText : null,
      ),
    );
  }
}
