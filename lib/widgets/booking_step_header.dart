import 'package:flutter/material.dart';

class BookingStepHeader extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const BookingStepHeader({
    Key? key,
    required this.showBackButton,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (showBackButton && onBackPressed != null)
            GestureDetector(
              onTap: onBackPressed,
              child: Icon(Icons.arrow_back_ios, size: 20),
            ),
        ],
      ),
    );
  }
}