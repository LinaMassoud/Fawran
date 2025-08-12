import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fawran/generated/app_localizations.dart';

class ServiceChoicePage extends StatelessWidget {
  const ServiceChoicePage({super.key});

  void _handleChoice(BuildContext context, String serviceName) {
    // Navigate based on selected service
    if (serviceName == AppLocalizations.of(context)!.hourlyMaid) {
      Navigator.of(context).pushNamed('/hourly');
    } else if (serviceName == AppLocalizations.of(context)!.permanentMaid) {
      Navigator.of(context).pushNamed('/selectAddress');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
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
              isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: Color(0xFFFFA200),
              size: 20,
            ),
          ),
        ),
        title: Text(
          localizations.chooseService,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFA200),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildServiceBox(
                context,
                title: localizations.hourlyMaid,
                icon: Icons.access_time,
                color: Colors.blue,
                isHourly: true,
              ),
              const SizedBox(height: 30),
              _buildServiceBox(
                context,
                title: localizations.permanentMaid,
                icon: Icons.cleaning_services,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHourly 
                ? Color(0xFF3789C8)
                : Color(0xFFFFA200),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isHourly
                  ? Color(0xFF3789C8).withOpacity(0.4)
                  : Color(0xFFFFA200).withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isHourly)
              SvgPicture.asset(
                'assets/icons/clock.svg',
                width: 76,
                height: 76,
                color: Color(0xFF1E49A0),
              )
            else
              SvgPicture.asset(
                'assets/icons/permanent_maid.svg',
                width: 76,
                height: 76,
                color: Color(0xFFFF5722),
              ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isHourly 
                    ? Color(0xFF1E49A0)
                    : Color(0xFFFF5722),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}