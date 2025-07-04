import 'package:fawran/screens/login_screen.dart';
import 'package:flutter/material.dart';

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

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  
  // Animation duration constants
  static const Duration kCircle1Duration = Duration(seconds: 8);
  static const Duration kCircle2Duration = Duration(seconds: 10);
  static const Duration kCircle3Duration = Duration(seconds: 6);
  
  // Layout offset constants
  static const double kCircle1BaseLeft = -80;
  static const double kCircle1MovementMultiplier = 60;
  static const double kCircle2BaseRight = -100;
  static const double kCircle2MovementMultiplier = 50;
  static const double kCircle3MovementMultiplier = 80;
  
  // Circle size constants
  static const double kCircle1Size = 200;
  static const double kCircle2Size = 250;
  static const double kCircle3Size = 180;
  
  late final PageController _pageController;
  int _currentPage = 0;

  // Animation controllers for the circles
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;

  // Animations for each circle
  late Animation<Offset> _circle1Animation;
  late Animation<Offset> _circle2Animation;
  late Animation<Offset> _circle3Animation;

  // Different content for each onboarding screen
  final List<OnboardingContent> _onboardingData = [
    OnboardingContent(
      title: "Flexible Service Solutions",
      description: "Fawran service provides trained and\nqualified labors on an hourly basis\nwith flexible scheduling options",
    ),
    OnboardingContent(
      title: "Trained & Qualified Staff",
      description: "Our verified professionals deliver\nquality service with weekly or\nmonthly contracts available",
    ),
    OnboardingContent(
      title: "Schedule Based on Your Needs",
      description: "All services are scheduled based\non your specific requests and\npreferred timing",
    ),
    OnboardingContent(
      title: "Complete Service Management",
      description: "From booking to completion,\nmanage all your domestic service\nrequirements in one place",
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize PageController in initState for better lifecycle management
    _pageController = PageController();
    
    // Initialize animation controllers with duration constants
    _circle1Controller = AnimationController(
      duration: kCircle1Duration,
      vsync: this,
    );
    
    _circle2Controller = AnimationController(
      duration: kCircle2Duration,
      vsync: this,
    );
    
    _circle3Controller = AnimationController(
      duration: kCircle3Duration,
      vsync: this,
    );

    // Create different movement patterns for each circle
    _circle1Animation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.3, 0.2),
    ).animate(CurvedAnimation(
      parent: _circle1Controller,
      curve: Curves.easeInOut,
    ));

    _circle2Animation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-0.2, 0.3),
    ).animate(CurvedAnimation(
      parent: _circle2Controller,
      curve: Curves.easeInOut,
    ));

    _circle3Animation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.4, -0.1),
    ).animate(CurvedAnimation(
      parent: _circle3Controller,
      curve: Curves.easeInOut,
    ));

    // Start animations with repeat and reverse for smooth back-and-forth movement
    _circle1Controller.repeat(reverse: true);
    _circle2Controller.repeat(reverse: true);
    _circle3Controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Stack(
        children: [
          // Full background with gradient
          Container(
            height: screenHeight,
            width: screenWidth,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF06214B),
                  Color(0xFF06214B),
                ],
              ),
            ),
          ),
          
          // Animated decorative circles positioned across the background
          AnimatedBuilder(
            animation: _circle1Animation,
            builder: (context, child) {
              return Positioned(
                left: kCircle1BaseLeft + (_circle1Animation.value.dx * kCircle1MovementMultiplier),
                top: screenHeight * 0.1 + (_circle1Animation.value.dy * 40),
                child: Container(
                  width: kCircle1Size,
                  height: kCircle1Size,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          
          AnimatedBuilder(
            animation: _circle2Animation,
            builder: (context, child) {
              return Positioned(
                right: kCircle2BaseRight + (_circle2Animation.value.dx * kCircle2MovementMultiplier),
                top: screenHeight * 0.25 + (_circle2Animation.value.dy * 50),
                child: Container(
                  width: kCircle2Size,
                  height: kCircle2Size,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          
          AnimatedBuilder(
            animation: _circle3Animation,
            builder: (context, child) {
              return Positioned(
                left: screenWidth * 0.2 + (_circle3Animation.value.dx * kCircle3MovementMultiplier),
                bottom: screenHeight * 0.45 + (_circle3Animation.value.dy * 30),
                child: Container(
                  width: kCircle3Size,
                  height: kCircle3Size,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withOpacity(0.20),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          
          // Main content
          Column(
            children: [
              // Top section with logo and page indicators
              Container(
                height: screenHeight * 0.6, // Fixed height for top section
                child: SafeArea(
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.08),
                      
                      // Logo Section - "فورز" (Fawran in Arabic)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Arabic logo "فورز" with calligraphy styling
                          Text(
                            'فوراً',
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFF8A50),
                              fontFamily: 'serif', // Using serif for more calligraphic look
                              shadows: [
                                Shadow(
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.1),
                                ),
                              ],
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Emdad logo image positioned below
                          Image.asset(
                            'assets/images/emdad-logo.png', // Replace with your actual asset path
                            height: 32, // Adjust height as needed
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Page indicators positioned lower
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_onboardingData.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? const Color(0xFFFF8A50)
                                    : Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom white container - fills remaining space
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
                    top: false, // Don't apply safe area to top since we handle it above
                    child: Padding(
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
                              
                              // Bottom buttons
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (_currentPage < _onboardingData.length - 1)
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
                                      )
                                    else
                                      const SizedBox(width: 60),
                                    ElevatedButton(
                                      onPressed: _currentPage < _onboardingData.length - 1 ? _nextPage : () {
                                        // Handle get started action
                                         Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                                        print('Get Started pressed');
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
                                      child: Text(
                                        _currentPage < _onboardingData.length - 1 ? 'Next' : 'Get Started',
                                        style: const TextStyle(
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}