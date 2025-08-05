import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ServiceChoicePage extends StatelessWidget {
  const ServiceChoicePage({super.key});

  void _handleChoice(BuildContext context, String serviceName) {
    // Navigate based on selected service
    if (serviceName == 'Hourly Maid') {
      Navigator.of(context).pushNamed('/hourly');
    } else if (serviceName == 'Permanent Maid') {
      Navigator.of(context).pushNamed('/selectAddress');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 65,
        backgroundColor: Color(0xFF10295C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
          child: Container(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios,
              color: Color(0xFFFFA200),
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Choose Service',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFA200),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80), // Reduced spacing from header
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Changed to start
            children: [
              _buildServiceBox(
                context,
                title: 'Hourly Maid',
                icon: Icons.access_time,
                color: Colors.blue,
                isHourly: true,
              ),
              const SizedBox(height: 40), // Reduced spacing between boxes
              _buildServiceBox(
                context,
                title: 'Permanent Maid',
                icon: Icons.cleaning_services, // This will be ignored for permanent maid
                color: Color(0xFFFFA200),
                isHourly: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceBox(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color color,
  required bool isHourly,
}) {
  return GestureDetector(
    onTap: () => _handleChoice(context, title),
    child: Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: isHourly 
            ? Color(0xFFE0EAFF) // var(--White-Blue)
            : Color(0xFFFFF3E0), // Light orange/peach background for permanent
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHourly 
              ? Color(0xFF3789C8) // border: 1px solid #3789C8
              : Color(0xFFFF9800), // Orange border for permanent
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isHourly)
            Icon(
              Icons.access_time,
              size: 64,
              color: Color(0xFF1E49A0), // var(--Second-blue)
            )
          else
            SvgPicture.asset(
              'assets/images/permanent_maid.svg',
              width: 64,
              height: 64,
              color: Color(0xFFFF5722), // Orange-red color for permanent maid icon
            ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isHourly 
                  ? Color(0xFF1E49A0) // var(--Second-blue)
                  : Color(0xFFFF5722), // Orange-red text for permanent
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

}