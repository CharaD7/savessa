import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/shared/widgets/loaders/gradient_square_loader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Navigate to language selection screen
        context.go('/language');
      }
    });
    
    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _animationController.forward();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      // Use a gradient background with purple colors
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
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo with animation
                // In production, replace with actual Lottie animation
                // For now, we'll use a placeholder with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Create a bounce effect
                    final bounce = Curves.elasticOut.transform(
                      _animationController.value
                    );
                    
                    return Transform.scale(
                      scale: 0.8 + (0.2 * bounce),
                      child: Container(
                        width: size.width * 0.4,
                        height: size.width * 0.4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondary,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // App name
                Text(
                  'Savessa',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Welcome message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Welcome to Savessa – Your Community Savings Companion.',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Loading indicator
                GradientSquareLoader(
                  size: 60,
                  color1: theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}