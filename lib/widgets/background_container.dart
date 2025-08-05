import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fawran/generated/app_localizations.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;
  final double? topSectionHeight;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? topRightWidget;
  final EdgeInsets? padding;

  const BackgroundContainer({
    Key? key,
    required this.child,
    this.topSectionHeight,
    this.showBackButton = false,
    this.onBackPressed,
    this.topRightWidget,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveTopHeight = topSectionHeight ?? screenHeight * 0.4;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Fixed SVG Background Image - using MediaQuery.of(context).size to get original screen size
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height, // Use original screen height
            child: SvgPicture.asset(
              'assets/images/onboarding_background.svg',
              fit: BoxFit.cover,
              width: screenWidth,
              height: MediaQuery.of(context).size.height,
            ),
          ),

          // Main content overlay
          Column(
            children: [
              // Top section with background
              Container(
                height: effectiveTopHeight,
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Top right widget (language switcher, etc.)
                      if (topRightWidget != null)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: topRightWidget!,
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom white container - fills remaining space and allows scrolling
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: padding ?? const EdgeInsets.all(24),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back button with text positioned as overlay
          if (showBackButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16, // Account for status bar
              left: 16,
              child: GestureDetector(
                onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chevron_left,
                        color: Color(0xFFFFA200),
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.back,
                        style: const TextStyle(
                          color: Color(0xFFFFA200),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}