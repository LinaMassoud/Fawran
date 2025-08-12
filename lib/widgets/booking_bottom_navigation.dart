import 'package:flutter/material.dart';
import 'package:fawran/generated/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 55), // Added more bottom padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E49A0).withOpacity(0.15), // Blue tinted shadow
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, -5),
          ),
          BoxShadow(
            color: Color(0xFF1E49A0).withOpacity(0.08), // Additional lighter blue shadow
            blurRadius: 40,
            spreadRadius: 5,
            offset: Offset(0, -10),
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
                  loc.startingFrom,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF091735),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'SAR ${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFFF2582A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Spacer(), // Push the button to the rightmost side
            // Next Button positioned at the rightmost edge when price > 0
            Container(
              width: MediaQuery.of(context).size.width * 0.50, // Smaller width when price is shown
              child: ElevatedButton(
                onPressed: canProceed ? onNextPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canProceed 
                      ? Color(0xFF10295C)
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: canProceed ? 2 : 0,
                ),
                child: Text(
                  isLastStep ? 'Complete Booking' : loc.next,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Next Button centered with reduced width when price = 0
            Expanded(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // Reduced width when centered
                  child: ElevatedButton(
                    onPressed: canProceed ? onNextPressed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canProceed 
                          ? Color(0xFF10295C)
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: canProceed ? 2 : 0,
                    ),
                    child: Text(
                      isLastStep ? 'Complete Booking' : loc.next,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}