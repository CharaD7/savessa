import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import screens as they are created
// import '../../features/auth/presentation/screens/login_screen.dart';
// import '../../features/auth/presentation/screens/register_screen.dart';
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
        builder: (context, state) => const PlaceholderScreen(title: 'Splash'),
      ),
      
      // Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const PlaceholderScreen(title: 'Register'),
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
            builder: (context, state) => const PlaceholderScreen(title: 'Home'),
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
        builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
      ),
      
      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const PlaceholderScreen(title: 'Notifications'),
      ),
    ],
    
    // Redirect to login if not authenticated
    redirect: (context, state) {
      // This will be implemented when authentication is set up
      // For now, we'll just return null to allow all navigation
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
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