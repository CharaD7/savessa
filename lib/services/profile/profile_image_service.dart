import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service to handle profile image operations
class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  
  /// Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Show image source selection dialog (gallery or camera)
  Future<XFile?> pickImageWithSourceSelection() async {
    // This method should be called from UI with a dialog
    // For now, default to gallery
    return pickImage(source: ImageSource.gallery);
  }

  /// Save image to local storage and return the file path
  Future<String?> saveImageLocally(XFile imageFile, String userId) async {
    try {
      // Get application documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String profileImagesDir = path.join(appDocDir.path, 'profile_images');
      
      // Create directory if it doesn't exist
      final Directory directory = Directory(profileImagesDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate unique filename using user ID and timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(imageFile.path);
      final String fileName = '${userId}_$timestamp$extension';
      final String filePath = path.join(profileImagesDir, fileName);

      // Read image data
      final Uint8List imageData = await imageFile.readAsBytes();
      
      // Write to local file
      final File localFile = File(filePath);
      await localFile.writeAsBytes(imageData);

      debugPrint('Profile image saved locally: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }

  /// Get local profile image path for user
  Future<String?> getLocalProfileImagePath(String userId) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String profileImagesDir = path.join(appDocDir.path, 'profile_images');
      final Directory directory = Directory(profileImagesDir);
      
      if (!await directory.exists()) {
        return null;
      }

      // Find the most recent profile image for this user
      final List<FileSystemEntity> files = directory.listSync()
          .where((file) => file is File && path.basename(file.path).startsWith('${userId}_'))
          .toList();

      if (files.isEmpty) {
        return null;
      }

      // Sort by modification time, newest first
      files.sort((a, b) => File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()));
      
      return files.first.path;
    } catch (e) {
      debugPrint('Error getting local profile image: $e');
      return null;
    }
  }

  /// Delete old profile images for user (keep only the latest)
  Future<void> cleanupOldProfileImages(String userId) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String profileImagesDir = path.join(appDocDir.path, 'profile_images');
      final Directory directory = Directory(profileImagesDir);
      
      if (!await directory.exists()) {
        return;
      }

      // Find all profile images for this user
      final List<FileSystemEntity> files = directory.listSync()
          .where((file) => file is File && path.basename(file.path).startsWith('${userId}_'))
          .toList();

      if (files.length <= 1) {
        return; // Keep at least one image
      }

      // Sort by modification time, newest first
      files.sort((a, b) => File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()));
      
      // Delete all but the first (newest) image
      for (int i = 1; i < files.length; i++) {
        await files[i].delete();
        debugPrint('Deleted old profile image: ${files[i].path}');
      }
    } catch (e) {
      debugPrint('Error cleaning up old profile images: $e');
    }
  }


  /// Validate image file
  bool validateImage(XFile imageFile) {
    final String extension = path.extension(imageFile.path).toLowerCase();
    final List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    
    return allowedExtensions.contains(extension);
  }

  /// Get image size in bytes
  Future<int> getImageSize(XFile imageFile) async {
    try {
      return await imageFile.length();
    } catch (e) {
      debugPrint('Error getting image size: $e');
      return 0;
    }
  }

  /// Check if image size is acceptable (max 5MB)
  Future<bool> isImageSizeAcceptable(XFile imageFile, {int maxSizeInBytes = 5 * 1024 * 1024}) async {
    final int size = await getImageSize(imageFile);
    return size <= maxSizeInBytes;
  }

  /// Convert local file path to a URL-like string for database storage
  String localPathToUrl(String localPath) {
    return 'local://$localPath';
  }

  /// Convert URL-like string back to local file path
  String urlToLocalPath(String url) {
    if (url.startsWith('local://')) {
      return url.substring(8); // Remove 'local://' prefix
    }
    return url; // Assume it's already a local path or external URL
  }

  /// Check if a URL represents a local image
  bool isLocalImageUrl(String url) {
    return url.startsWith('local://') || (url.contains('/profile_images/') && !url.startsWith('http'));
  }

  /// Generate avatar initials from name
  String generateAvatarInitials(String firstName, String lastName) {
    final String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  /// Get avatar background color based on user initials
  int getAvatarColorCode(String initials) {
    if (initials.isEmpty) return 0xFF9C27B0; // Default purple
    
    final List<int> colors = [
      0xFF9C27B0, // Purple
      0xFF2196F3, // Blue  
      0xFF009688, // Teal
      0xFF4CAF50, // Green
      0xFFFF9800, // Orange
      0xFFF44336, // Red
      0xFF795548, // Brown
      0xFF607D8B, // Blue Grey
      0xFFE91E63, // Pink
      0xFF3F51B5, // Indigo
    ];
    
    // Use hash of initials to consistently pick a color
    final int hash = initials.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
