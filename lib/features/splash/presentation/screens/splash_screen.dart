import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/shared/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for the logo animation to finish before navigating
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      context.go('/language');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // Reverted to original purple gradient background
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
                // App logo with ripple/shimmer/sparkles
                const AppLogo(
                  size: 140,
                  animate: true,
                  glow: true,
                  repeat: false, // play once
                  assetPath: 'assets/images/logo.png',
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
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}