import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceChoicePage extends ConsumerWidget {
  const ServiceChoicePage({super.key});

  void _handleChoice(BuildContext context, String serviceName) {
    final localizations = AppLocalizations.of(context)!;
    // Navigate based on selected service
    if (serviceName == localizations.hourlyMaid) {
      Navigator.of(context).pushNamed('/hourly');
    } else if (serviceName == localizations.permanentMaid) {
      Navigator.of(context).pushNamed('/selectAddress');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
            localizations.chooseService,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFA200),
              fontFamily: 'Poppins',
            ),
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                  isArabic: isArabic,
                ),
                const SizedBox(height: 30),
                _buildServiceBox(
                  context,
                  title: localizations.permanentMaid,
                  icon: Icons.cleaning_services,
                  color: Color(0xFFFFA200),
                  isHourly: false,
                  isArabic: isArabic,
                ),
              ],
            ),
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
    required bool isArabic,
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
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}