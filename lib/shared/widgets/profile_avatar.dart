import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:savessa/services/profile/profile_image_service.dart';

/// A reusable profile avatar widget that displays either:
/// - Profile image (local or network)
/// - User initials with colored background
/// - Default icon
class ProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String firstName;
  final String lastName;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;
  final IconData? fallbackIcon;
  
  const ProfileAvatar({
    super.key,
    this.profileImageUrl,
    required this.firstName,
    required this.lastName,
    this.radius = 28,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileService = ProfileImageService();
    final initials = profileService.generateAvatarInitials(firstName, lastName);
    final avatarColor = Color(profileService.getAvatarColorCode(initials));
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: showBorder
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor ?? theme.colorScheme.primary,
                  width: borderWidth ?? 2.0,
                ),
              )
            : null,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: avatarColor,
          backgroundImage: _buildBackgroundImage(),
          child: _buildChild(theme, initials, avatarColor),
        ),
      ),
    );
  }

  ImageProvider? _buildBackgroundImage() {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return null;
    }

    final profileService = ProfileImageService();
    
    // Handle local images
    if (profileService.isLocalImageUrl(profileImageUrl!)) {
      final localPath = profileService.urlToLocalPath(profileImageUrl!);
      final file = File(localPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
      return null; // Fall back to initials
    }
    
    // Handle network images
    if (profileImageUrl!.startsWith('http')) {
      return CachedNetworkImageProvider(profileImageUrl!);
    }
    
    return null;
  }

  Widget? _buildChild(ThemeData theme, String initials, Color avatarColor) {
    // If we have a profile image, don't show anything on top
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      final profileService = ProfileImageService();
      
      // Check if local image exists
      if (profileService.isLocalImageUrl(profileImageUrl!)) {
        final localPath = profileService.urlToLocalPath(profileImageUrl!);
        final file = File(localPath);
        if (file.existsSync()) {
          return null; // Image will be shown as background
        }
      } else if (profileImageUrl!.startsWith('http')) {
        // For network images, show loading/error handling
        return null; // Let CachedNetworkImage handle it
      }
    }
    
    // Show initials if available
    if (initials.isNotEmpty) {
      return Text(
        initials,
        style: TextStyle(
          color: _getContrastingTextColor(avatarColor),
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    
    // Fallback to icon
    return Icon(
      fallbackIcon ?? Icons.person,
      color: _getContrastingTextColor(avatarColor),
      size: radius * 0.8,
    );
  }

  /// Get contrasting text color for the avatar background
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance to determine if we should use light or dark text
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// A profile avatar with loading state for network images
class NetworkProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String firstName;
  final String lastName;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;
  
  const NetworkProfileAvatar({
    super.key,
    this.profileImageUrl,
    required this.firstName,
    required this.lastName,
    this.radius = 28,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileService = ProfileImageService();
    final initials = profileService.generateAvatarInitials(firstName, lastName);
    final avatarColor = Color(profileService.getAvatarColorCode(initials));
    
    if (profileImageUrl != null && 
        profileImageUrl!.isNotEmpty && 
        profileImageUrl!.startsWith('http')) {
      
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: showBorder
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor ?? theme.colorScheme.primary,
                    width: borderWidth ?? 2.0,
                  ),
                )
              : null,
          child: CachedNetworkImage(
            imageUrl: profileImageUrl!,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: radius,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => CircleAvatar(
              radius: radius,
              backgroundColor: avatarColor.withValues(alpha: 0.5),
              child: SizedBox(
                width: radius * 0.8,
                height: radius * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getContrastingTextColor(avatarColor),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => ProfileAvatar(
              profileImageUrl: null, // Fall back to initials
              firstName: firstName,
              lastName: lastName,
              radius: radius,
              showBorder: false, // Border is handled by outer container
            ),
          ),
        ),
      );
    }
    
    // For local images or no image, use the regular ProfileAvatar
    return ProfileAvatar(
      profileImageUrl: profileImageUrl,
      firstName: firstName,
      lastName: lastName,
      radius: radius,
      onTap: onTap,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
  }

  Color _getContrastingTextColor(Color backgroundColor) {
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// Profile avatar specifically for list items or cards (smaller size)
class ListProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String firstName;
  final String lastName;
  final VoidCallback? onTap;
  
  const ListProfileAvatar({
    super.key,
    this.profileImageUrl,
    required this.firstName,
    required this.lastName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      profileImageUrl: profileImageUrl,
      firstName: firstName,
      lastName: lastName,
      radius: 20,
      onTap: onTap,
    );
  }
}

/// Large profile avatar for profile screens
class LargeProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String firstName;
  final String lastName;
  final VoidCallback? onTap;
  final bool showBorder;
  
  const LargeProfileAvatar({
    super.key,
    this.profileImageUrl,
    required this.firstName,
    required this.lastName,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkProfileAvatar(
      profileImageUrl: profileImageUrl,
      firstName: firstName,
      lastName: lastName,
      radius: 60,
      onTap: onTap,
      showBorder: showBorder,
    );
  }
}
