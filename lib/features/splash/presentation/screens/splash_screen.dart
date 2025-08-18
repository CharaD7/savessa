import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/shared/widgets/app_logo.dart';
import 'package:savessa/shared/widgets/petal_ripple_background.dart';

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
      body: Stack(
        children: [
          // Animated petal ripple background (lightweight CustomPainter)
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, -40), // move background up by 40px total
              child: const PetalRippleBackground(centerAlignment: Alignment(0.0, -0.12)),
            ),
          ),
          // Foreground content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo with faint pulsing glow and subtle zoom
                  const AppLogo(
                    size: 180,
                    animate: true,
                    glow: true,
                    repeat: false, // play once for splash
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
                      shadows: const [
                        Shadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Welcome message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Welcome to Savessa – Your Community Savings Companion.',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
                        fontSize: 18,
                        shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}