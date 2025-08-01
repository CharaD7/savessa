import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import screens
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/language/presentation/screens/language_selection_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/role/presentation/screens/role_selection_screen.dart';
import '../../features/account/presentation/screens/account_setup_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../constants/icon_mapping.dart';
import '../theme/theme_demo.dart';
// import '../../features/savings/presentation/screens/savings_screen.dart';
// etc.

// For now, we'll create placeholder screens
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({super.key, required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Screen')),
    );
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Language selection screen
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      
      // Onboarding screen
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Role selection screen
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      
      // Account setup screen
      GoRoute(
        path: '/account-setup',
        builder: (context, state) => const AccountSetupScreen(),
      ),
      
      // Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          // Extract the selected role from state.extra
          final selectedRole = state.extra as String?;
          return RegisterScreen(selectedRole: selectedRole);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const PlaceholderScreen(title: 'Forgot Password'),
      ),
      
      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          // Home/Dashboard
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Savings
          GoRoute(
            path: '/savings',
            builder: (context, state) => const PlaceholderScreen(title: 'Savings'),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const PlaceholderScreen(title: 'Add Savings'),
              ),
              GoRoute(
                path: 'history',
                builder: (context, state) => const PlaceholderScreen(title: 'Savings History'),
              ),
            ],
          ),
          
          // Groups
          GoRoute(
            path: '/groups',
            builder: (context, state) => const PlaceholderScreen(title: 'Groups'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const PlaceholderScreen(title: 'Create Group'),
              ),
              GoRoute(
                path: ':groupId',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId'] ?? '';
                  return PlaceholderScreen(title: 'Group Details: $groupId');
                },
              ),
            ],
          ),
          
          // Analytics
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const PlaceholderScreen(title: 'Analytics'),
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const PlaceholderScreen(title: 'Profile'),
          ),
        ],
      ),
      
      // Payment routes
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PlaceholderScreen(title: 'Payments'),
        routes: [
          GoRoute(
            path: 'flutterwave',
            builder: (context, state) => const PlaceholderScreen(title: 'Flutterwave Payment'),
          ),
          GoRoute(
            path: 'paystack',
            builder: (context, state) => const PlaceholderScreen(title: 'Paystack Payment'),
          ),
        ],
      ),
      
      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'theme',
            builder: (context, state) => const ThemeDemoScreen(),
          ),
        ],
      ),
      
      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const PlaceholderScreen(title: 'Notifications'),
      ),
    ],
    
    // Redirect logic
    redirect: (context, state) {
      // Redirect from account-setup to login since we're no longer using the account setup screen
      if (state.matchedLocation == '/account-setup') {
        return '/login';
      }
      
      // This will be expanded when authentication is set up
      // For now, we'll just return null for other routes to allow all navigation
      return null;
    },
  );
}

// Scaffold with bottom navigation bar for the main app shell
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  
  const ScaffoldWithBottomNav({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(IconMapping.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(IconMapping.savings),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Icon(IconMapping.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(IconMapping.barChart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(IconMapping.profile),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/savings')) {
      return 1;
    }
    if (location.startsWith('/groups')) {
      return 2;
    }
    if (location.startsWith('/analytics')) {
      return 3;
    }
    if (location.startsWith('/profile')) {
      return 4;
    }
    return 0;
  }
  
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
        break;
      case 1:
        GoRouter.of(context).go('/savings');
        break;
      case 2:
        GoRouter.of(context).go('/groups');
        break;
      case 3:
        GoRouter.of(context).go('/analytics');
        break;
      case 4:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}