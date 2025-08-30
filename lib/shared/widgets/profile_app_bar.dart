import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/user/user_data_service.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/shared/widgets/profile_avatar.dart';

/// A custom app bar that displays a user profile avatar instead of a title
class ProfileAppBar extends StatefulWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double elevation;
  final Widget? leading;
  final VoidCallback? onProfileTap;

  const ProfileAppBar({
    super.key,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation = 0,
    this.leading,
    this.onProfileTap,
  });

  @override
  State<ProfileAppBar> createState() => _ProfileAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ProfileAppBarState extends State<ProfileAppBar> {
  String? _profileImageUrl;
  String _firstName = '';
  String _lastName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDataService = Provider.of<UserDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Try to get user data from UserDataService first
      if (userDataService.user != null) {
        setState(() {
          _firstName = userDataService.user!['first_name']?.toString() ?? '';
          _lastName = userDataService.user!['last_name']?.toString() ?? '';
          _profileImageUrl = userDataService.user!['profile_image_url']?.toString();
          _loading = false;
        });
        return;
      }

      // Fallback to database lookup
      final userId = userDataService.id ?? authService.postgresUserId;
      if (userId != null && userId.isNotEmpty) {
        final db = DatabaseService();
        final userData = await db.getUserById(userId);
        
        if (userData != null) {
          setState(() {
            _firstName = userData['first_name']?.toString() ?? '';
            _lastName = userData['last_name']?.toString() ?? '';
            _profileImageUrl = userData['profile_image_url']?.toString();
            _loading = false;
          });
          return;
        }
      }

      // Fallback to Firebase user data
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        final displayName = currentUser.displayName ?? '';
        final parts = displayName.split(' ');
        setState(() {
          _firstName = parts.isNotEmpty ? parts.first : 'User';
          _lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
          _profileImageUrl = currentUser.photoURL;
          _loading = false;
        });
        return;
      }

      // Final fallback
      setState(() {
        _firstName = 'User';
        _lastName = '';
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data for profile app bar: $e');
      setState(() {
        _firstName = 'User';
        _lastName = '';
        _loading = false;
      });
    }
  }

  void _onProfileTap() {
    if (widget.onProfileTap != null) {
      widget.onProfileTap!();
    } else {
      // Default navigation to profile screen
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: widget.backgroundColor,
      elevation: widget.elevation,
      leading: widget.leading ?? (_loading
          ? const SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: _onProfileTap,
                child: ProfileAvatar(
                  profileImageUrl: _profileImageUrl,
                  firstName: _firstName,
                  lastName: _lastName,
                  radius: 20,
                  showBorder: true,
                  borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderWidth: 1.5,
                ),
              ),
            )),
      actions: widget.actions,
    );
  }
}

/// A specialized profile app bar for home screens with additional functionality
class HomeProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final VoidCallback? onProfileTap;

  const HomeProfileAppBar({
    super.key,
    this.actions,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAppBar(
      actions: actions,
      onProfileTap: onProfileTap,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Profile app bar for screens that need back navigation
class ProfileAppBarWithBack extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackPressed;

  const ProfileAppBarWithBack({
    super.key,
    this.actions,
    this.onProfileTap,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAppBar(
      automaticallyImplyLeading: true,
      actions: actions,
      onProfileTap: onProfileTap,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A simple profile tile for use in drawers or lists
class ProfileTile extends StatefulWidget {
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const ProfileTile({
    super.key,
    this.onTap,
    this.padding,
  });

  @override
  State<ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<ProfileTile> {
  String? _profileImageUrl;
  String _firstName = '';
  String _lastName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDataService = Provider.of<UserDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Try UserDataService first
      if (userDataService.user != null) {
        setState(() {
          _firstName = userDataService.user!['first_name']?.toString() ?? '';
          _lastName = userDataService.user!['last_name']?.toString() ?? '';
          _email = userDataService.user!['email']?.toString() ?? '';
          _profileImageUrl = userDataService.user!['profile_image_url']?.toString();
        });
        return;
      }

      // Fallback to database
      final userId = userDataService.id ?? authService.postgresUserId;
      if (userId != null && userId.isNotEmpty) {
        final db = DatabaseService();
        final userData = await db.getUserById(userId);
        
        if (userData != null) {
          setState(() {
            _firstName = userData['first_name']?.toString() ?? '';
            _lastName = userData['last_name']?.toString() ?? '';
            _email = userData['email']?.toString() ?? '';
            _profileImageUrl = userData['profile_image_url']?.toString();
          });
          return;
        }
      }

      // Firebase fallback
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        setState(() {
          _email = currentUser.email ?? '';
          _profileImageUrl = currentUser.photoURL;
          final displayName = currentUser.displayName ?? '';
          final parts = displayName.split(' ');
          _firstName = parts.isNotEmpty ? parts.first : 'User';
          _lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data for profile tile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ProfileAvatar(
        profileImageUrl: _profileImageUrl,
        firstName: _firstName,
        lastName: _lastName,
        radius: 24,
        showBorder: true,
      ),
      title: Text(
        _firstName.isNotEmpty || _lastName.isNotEmpty 
            ? '$_firstName $_lastName'.trim()
            : 'User',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: _email.isNotEmpty 
          ? Text(
              _email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: widget.onTap ?? () => context.go('/profile'),
    );
  }
}
