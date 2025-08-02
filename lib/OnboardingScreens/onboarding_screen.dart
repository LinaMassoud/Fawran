import 'package:fawran/screens/login_screen.dart';
import 'package:fawran/OnboardingScreens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/background_container.dart'; // Import the reusable component

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
    _checkLocationPermission();
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
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _onboardingData[index].title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B4C7E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _onboardingData[index].description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
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
                                fontSize: 16,
                                color: Color(0xFF2B4C7E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          // Page indicators in the center (excluding the last page)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                                _onboardingData.length - 1, (indicatorIndex) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentPage == indicatorIndex ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == indicatorIndex
                                      ? const Color(0xFF06214B)
                                      : Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
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
                                horizontal: 28,
                                vertical: 14,
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