import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/user/user_data_service.dart';

// Import screens
import 'package:savessa/features/splash/presentation/screens/splash_screen.dart';
import 'package:savessa/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:savessa/features/language/presentation/screens/language_selection_screen.dart';
import 'package:savessa/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:savessa/features/role/presentation/screens/role_selection_screen.dart';
import 'package:savessa/features/account/presentation/screens/account_setup_screen.dart';
import 'package:savessa/features/auth/presentation/screens/login_screen.dart';
import 'package:savessa/features/auth/presentation/screens/register_screen.dart';
import 'package:savessa/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:savessa/features/auth/presentation/screens/password_reset_success_screen.dart';
import 'package:savessa/features/home/presentation/screens/home_screen.dart';
import 'package:savessa/features/home/presentation/screens/manager_home_screen.dart';
import 'package:savessa/features/home/presentation/screens/enhanced_home_screen.dart';
import 'package:savessa/features/settings/presentation/screens/settings_screen.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/theme_demo.dart';
import 'package:savessa/features/security/presentation/screens/two_factor_screen.dart';
import 'package:savessa/features/security/presentation/screens/totp_setup_screen.dart';
import 'package:savessa/features/security/presentation/screens/otp_verify_screen.dart';
import 'package:savessa/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:savessa/features/settings/presentation/screens/audit_log_screen.dart';
// import '../../features/savings/presentation/screens/savings_screen.dart';
// etc.

import 'package:savessa/features/savings/presentation/screens/savings_screen.dart';
import 'package:savessa/features/savings/presentation/screens/add_savings_screen.dart';
import 'package:savessa/features/savings/presentation/screens/my_contributions_screen.dart';
import 'package:savessa/features/profile/presentation/screens/profile_screen.dart';
import 'package:savessa/features/groups/presentation/screens/groups_screen.dart';
import 'package:savessa/features/groups/presentation/screens/join_group_screen.dart';
import 'package:savessa/features/groups/presentation/screens/create_group_screen.dart';
import 'package:savessa/features/members/presentation/screens/add_member_screen.dart';

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
        builder: (context, state) {
          // Extract the selected role from state.extra
          final selectedRole = state.extra as String?;
          return AccountSetupScreen(
            key: UniqueKey(),
            selectedRole: selectedRole,
          );
        },
      ),
      
      // Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final extra = state.extra;
          String? role;
          bool hideSignup = false;
          if (extra is String) {
            role = extra;
          } else if (extra is Map<String, dynamic>) {
            role = extra['role'] as String?;
            hideSignup = (extra['hideSignup'] as bool?) ?? false;
          }
          return LoginScreen(selectedRole: role, hideSignupOption: hideSignup);
        },
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
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password-success',
        builder: (context, state) => const PasswordResetSuccessScreen(),
      ),
      
      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          // Home/Dashboard - contributor default
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          // Manager Dashboard
          GoRoute(
            path: '/home/manager',
            builder: (context, state) => const ManagerHomeScreen(),
          ),
          // Enhanced Home Screen (for testing new models/repositories)
          GoRoute(
            path: '/home/enhanced',
            builder: (context, state) => const EnhancedHomeScreen(),
          ),
          
          // Savings
          GoRoute(
            path: '/savings',
            builder: (context, state) => const SavingsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddSavingsScreen(),
              ),
              GoRoute(
                path: 'my',
                builder: (context, state) => const MyContributionsScreen(),
              ),
            ],
          ),
          
          // Groups
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  // Guard: only admins (managers) can create groups
                  try {
                    final role = Provider.of<UserDataService>(context, listen: false).role;
                    if (role != 'admin') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Only Savings Managers can create groups.')),
                        );
                        GoRouter.of(context).go('/groups');
                      });
                      return const PlaceholderScreen(title: 'Groups');
                    }
                  } catch (_) {}
                  return const CreateGroupScreen();
                },
              ),
              GoRoute(
                path: 'join',
                builder: (context, state) {
                  // Guard: only contributors can join
                  try {
                    final role = Provider.of<UserDataService>(context, listen: false).role;
                    if (role == 'admin') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Savings Managers cannot join groups.')),
                        );
                        GoRouter.of(context).go('/groups');
                      });
                      return const PlaceholderScreen(title: 'Groups');
                    }
                  } catch (_) {}
                  return const JoinGroupScreen();
                },
              ),
              GoRoute(
                path: 'add-member',
                builder: (context, state) {
                  // Guard: only admins can add members
                  try {
                    final role = Provider.of<UserDataService>(context, listen: false).role;
                    if (role != 'admin') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Only Savings Managers can add members.')),
                        );
                        GoRouter.of(context).go('/groups');
                      });
                      return const PlaceholderScreen(title: 'Groups');
                    }
                  } catch (_) {}
                  final groupId = state.uri.queryParameters['groupId'];
                  return AddMemberScreen(groupId: groupId);
                },
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
            builder: (context, state) => const AnalyticsScreen(),
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
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
              GoRoute(
                path: 'audit',
                builder: (context, state) => const AuditLogScreen(),
              ),
          GoRoute(
            path: 'two-factor',
            builder: (context, state) => const TwoFactorScreen(),
            routes: [
              GoRoute(
                path: 'totp',
                builder: (context, state) => const TotpSetupScreen(),
              ),
              GoRoute(
                path: 'otp',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final channel = (extra?['channel'] as String?) ?? 'sms';
                  return OtpVerifyScreen(channel: channel);
                },
              ),
            ],
          ),
        ],
      ),
      
// Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    
    // Redirect logic
    redirect: (context, state) {
      // Role-aware redirects
      // Safe read of AuthService; if not available, do nothing
      AuthService? auth;
      try {
        auth = Provider.of<AuthService>(context, listen: false);
      } catch (_) {
        return null;
      }
      final location = state.matchedLocation;
      // Wait until role is resolved (prevents flicker loops)
      if (!auth.roleResolved) return null;

      final isAdmin = auth.role == 'admin';
      final atManager = location.startsWith('/home/manager');
      final atHome = location == '/home' || location.startsWith('/home?');

      if (isAdmin) {
        // Admins prefer manager dashboard; if they hit /home, send to manager
        if (atHome) {
          return '/home/manager';
        }
        return null; // no change otherwise
      } else {
        // Members cannot access manager dashboard
        if (atManager) {
          return '/home';
        }
        return null;
      }
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
    }
  }
}