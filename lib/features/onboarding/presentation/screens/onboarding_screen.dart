import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/core/constants/icon_mapping.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isVoiceEnabled = true;
  
  // Onboarding content
  final List<Map<String, String>> _onboardingSteps = [
    {
      'title': 'Welcome to Savessa',
      'description': 'Here\'s how we help you save monthly with ease.',
      'image': 'assets/images/onboarding_1.png',
      'audio': 'assets/sounds/onboarding_1_en.mp3',
    },
    {
      'title': 'Create or Join Groups',
      'description': 'Start your own savings group or join an existing one with friends, family, or colleagues.',
      'image': 'assets/images/onboarding_2.png',
      'audio': 'assets/sounds/onboarding_2_en.mp3',
    },
    {
      'title': 'Track Contributions',
      'description': 'Easily record and monitor monthly contributions with transparent tracking.',
      'image': 'assets/images/onboarding_3.png',
      'audio': 'assets/sounds/onboarding_3_en.mp3',
    },
    {
      'title': 'Achieve Savings Goals',
      'description': 'Celebrate milestones and watch your community savings grow together.',
      'image': 'assets/images/onboarding_4.png',
      'audio': 'assets/sounds/onboarding_4_en.mp3',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Set system UI to be transparent for fullscreen effect
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Play the first narration when the screen loads
    _playNarration(_currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Play narration for the current page
  void _playNarration(int page) {
    if (!_isVoiceEnabled) return;
    
    // TODO: Implement audio playback when assets are available
    debugPrint('Playing narration for page ${page + 1}: ${_onboardingSteps[page]['audio']}');
  }

  // Navigate to the next page or finish onboarding
  void _nextPage() {
    if (_currentPage < _onboardingSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to role selection screen
      context.go('/role');
    }
  }

  // Navigate to the previous page
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Skip onboarding and go directly to role selection
  void _skipOnboarding() {
    // Navigate to role selection screen
    context.go('/role');
  }

  // Toggle voice narration
  void _toggleVoice() {
    setState(() {
      _isVoiceEnabled = !_isVoiceEnabled;
    });
    
    if (_isVoiceEnabled) {
      _playNarration(_currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.royalPurple,
              AppTheme.lightPurple,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header with voice toggle and skip button
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, statusBarHeight + 8.0, 16.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Voice toggle with glassmorphism effect
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isVoiceEnabled ? FeatherIcons.volume2 : FeatherIcons.volumeX,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _toggleVoice,
                      tooltip: _isVoiceEnabled ? 'Disable Voice' : 'Enable Voice',
                    ),
                  ),
                  
                  // Skip button with glassmorphism effect
                  Container(
decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content - PageView with onboarding cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingSteps.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _playNarration(page);
                },
                itemBuilder: (context, index) {
                  final step = _onboardingSteps[index];
                  
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image placeholder with animation and drop shadow
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.9, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: size.width * 0.7,
                                height: size.width * 0.7,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: theme.colorScheme.secondary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.gold.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _buildAnimatedIcon(index),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Title with glassmorphism effect
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            step['title']!,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description with glassmorphism effect
                        Container(
                          padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            step['description']!,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Progress indicator and navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Progress indicator with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingSteps.length,
                          (index) {
                            final isActive = _currentPage == index;
                            
                            return Container(
                              width: isActive ? 24 : 12,
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: isActive
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onPrimary.withValues(alpha: 0.3),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.gold.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Navigation buttons with drop shadows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (hidden on first page)
                      _currentPage > 0
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _previousPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.onPrimary,
                                  foregroundColor: theme.colorScheme.primary,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: const Icon(FeatherIcons.arrowLeft),
                              ),
                            )
                          : const SizedBox(width: 56), // Placeholder for spacing
                      
                      // Next/Finish button with drop shadow
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _currentPage < _onboardingSteps.length - 1
                                ? 'Next'
                                : 'Get Started',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build animated icon for each step
  Widget _buildAnimatedIcon(int step) {
    final iconData = _getIconForStep(step);
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(
            iconData,
            size: 80,
            color: AppTheme.gold,
          ),
        );
      },
    );
  }
  
  // Helper method to get icon for each step
  IconData _getIconForStep(int step) {
    switch (step) {
      case 0:
        return IconMapping.home; // Welcome icon
      case 1:
        return IconMapping.groupAdd; // Create or join groups
      case 2:
        return IconMapping.history; // Track contributions
      case 3:
        return IconMapping.barChart; // Achieve savings goals
      default:
        return IconMapping.infoOutline;
    }
  }
}