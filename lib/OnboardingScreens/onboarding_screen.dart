import 'package:fawran/screens/login_screen.dart';
import 'package:fawran/OnboardingScreens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add this import
import '../widgets/background_container.dart';

// Data class for onboarding content
class OnboardingContent {
  final String title;
  final String description;

  OnboardingContent({
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showSplash = true;
  final _secureStorage = const FlutterSecureStorage(); // Add this line

  // Different content for each onboarding screen
  final List<OnboardingContent> _onboardingData = [
    OnboardingContent(
      title: "Flexible Service Solutions",
      description:
          "Fawran service provides trained and\nqualified labors on an hourly basis\nwith flexible scheduling options",
    ),
    OnboardingContent(
      title: "Trained & Qualified Staff",
      description:
          "Our verified professionals deliver\nquality service with weekly or\nmonthly contracts available",
    ),
    OnboardingContent(
      title: "Book Your Service",
      description:
          "Choose the domestic solution that\nmatches your lifestyle and\npersonalized requirements",
    ),
    OnboardingContent(
      title: "Welcome To Home Service",
      description:
          "Our service is to help you to clean your\nhouse as quick as possible.",
    ),
    // Additional page for Get Started button
    OnboardingContent(
      title: "Welcome To Home Service",
      description:
          "Our service is to help you to clean your\nhouse as quick as possible.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _clearAuthTokens(); // Add this line to clear any existing tokens
    _checkLocationPermission();
  }

  // Add this method to clear authentication tokens
  Future<void> _clearAuthTokens() async {
    try {
      await _secureStorage.delete(key: 'token');
      await _secureStorage.delete(key: 'refresh_token');
      print('🧹 [ONBOARDING] Cleared authentication tokens');
    } catch (e) {
      print('❌ [ONBOARDING] Error clearing tokens: $e');
    }
  }

  void _handleSplashComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("صلاحية الموقع مرفوضة"),
          content: const Text("يجب تفعيل صلاحية الموقع من إعدادات التطبيق."),
          actions: [
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
              },
              child: const Text("فتح الإعدادات"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("إلغاء"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _onboardingData.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildOnboardingScreen() {
    final screenHeight = MediaQuery.of(context).size.height;

    return BackgroundContainer(
      topSectionHeight: screenHeight * 0.6,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemCount: _onboardingData.length,
        itemBuilder: (context, index) {
          // Check if this is the final "Get Started" page
          bool isGetStartedPage = index == _onboardingData.length - 1;
          
          return Stack(
            children: [
              // Main content in white container
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 85), // Add more space for title positioning
                        Text(
                          _onboardingData[index].description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280), // Updated color
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom section with buttons and page indicators
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: isGetStartedPage
                        ? // Get Started page layout - only show the button
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06214B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : // Regular pages layout - show skip, indicators, and next
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Skip button
                              TextButton(
                                onPressed: _skipToEnd,
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Color(0xFF1E49A0), // Updated to var(--Second-blue, #1E49A0)
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              // Page indicators in the center (excluding the last page)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                    _onboardingData.length - 1, (indicatorIndex) {
                                  bool isActive = _currentPage == indicatorIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: isActive ? 20 : 12,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFF1E49A0) // Active indicator
                                          : Colors.white, // Inactive: white fill
                                      border: isActive
                                          ? null
                                          : Border.all(
                                              color: const Color(0xFF1E49A0), // Blue border for inactive
                                              width: 1,
                                            ),
                                      borderRadius: BorderRadius.circular(6), // Fully rounded capsule shape
                                    ),
                                  );
                                }),
                              ),

                              // Next button
                              ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF06214B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              
              // Title positioned on top of the white container
              Positioned(
                top: 15, // Position slightly above the container edge
                left: 0,
                right: 0,
                child: Text(
                  _onboardingData[index].title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF091735), // Keep original dark color
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _showSplash 
          ? SplashScreen(
              duration: const Duration(seconds: 3),
              onSplashComplete: _handleSplashComplete,
            )
          : _buildOnboardingScreen(),
    );
  }
}