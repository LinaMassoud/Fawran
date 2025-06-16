import 'package:flutter/material.dart';

class BookingStepHeader extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final int currentStep;
  final int totalSteps;

  const BookingStepHeader({
    Key? key,
    required this.showBackButton,
    this.onBackPressed,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: onBackPressed,
              child: 
                Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
            )
          else
            SizedBox(width: 32), // Placeholder to maintain alignment
          
          Expanded(
            child: Center(
              child: Text(
                'Step $currentStep of $totalSteps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 32), // Balance the back button space
        ],
      ),
    );
  }
}