import 'package:flutter/material.dart';

class BookingBottomNavigation extends StatelessWidget {
  final double price;
  final bool canProceed;
  final bool isLastStep;
  final VoidCallback onNextPressed;

  const BookingBottomNavigation({
    Key? key,
    required this.price,
    required this.canProceed,
    required this.isLastStep,
    required this.onNextPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price Section - Only show if price > 0
          if (price > 0) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Starting From',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'SAR ${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(width: 20),
          ],
          
          SizedBox(width: 20),
          
          // Next/Complete Button
          Expanded(
            child: GestureDetector(
              onTap: canProceed ? onNextPressed : null,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: canProceed 
                      ? Color(0xFF1E3A8A) 
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isLastStep ? 'Complete Booking' : 'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}