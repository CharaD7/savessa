import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

/// This class provides a mapping from Material Icons to Feather Icons
/// to ensure consistency across the app.
class IconMapping {
  // Auth screens
  static const IconData person = FeatherIcons.user;
  static const IconData personOutline = FeatherIcons.user;
  static const IconData peopleOutline = FeatherIcons.users;
  static const IconData email = FeatherIcons.mail;
  static const IconData phone = FeatherIcons.phone;
  static const IconData lock = FeatherIcons.lock;
  static const IconData lockOpen = FeatherIcons.unlock;
  static const IconData lockOutline = FeatherIcons.lock;
  
  // Home screen
  static const IconData notifications = FeatherIcons.bell;
  static const IconData settings = FeatherIcons.settings;
  static const IconData infoOutline = FeatherIcons.info;
  static const IconData addCircle = FeatherIcons.plusCircle;
  static const IconData history = FeatherIcons.clock;
  static const IconData groupAdd = FeatherIcons.userPlus;
  static const IconData addBox = FeatherIcons.plus;
  static const IconData arrowUpward = FeatherIcons.arrowUp;
  static const IconData arrowDownward = FeatherIcons.arrowDown;
  static const IconData location = FeatherIcons.mapPin;
  static const IconData award = FeatherIcons.award;
  static const IconData edit = FeatherIcons.edit;
  static const IconData bell = FeatherIcons.bell;
  static const IconData cloudDone = FeatherIcons.cloud;
  static const IconData cloudSync = FeatherIcons.refreshCw;
  static const IconData cloudOff = FeatherIcons.cloudOff;
  static const IconData chevronRight = FeatherIcons.chevronRight;
  static const IconData chevronLeft = FeatherIcons.chevronLeft;
  static const IconData globe = FeatherIcons.globe;
  static const IconData droplet = FeatherIcons.droplet;
  static const IconData qr = FeatherIcons.grid; // QR-like
  static const IconData message = FeatherIcons.messageSquare;
  static const IconData logOut = FeatherIcons.logOut;
  static const IconData fileText = FeatherIcons.fileText;
  static const IconData helpCircle = FeatherIcons.helpCircle;
  
  // Bottom navigation
  static const IconData home = FeatherIcons.home;
  static const IconData savings = FeatherIcons.dollarSign;
  static const IconData group = FeatherIcons.users;
  static const IconData barChart = FeatherIcons.barChart2;
  static const IconData profile = FeatherIcons.user;
  
  // Text fields
  static const IconData clear = FeatherIcons.x;
  static const IconData visibilityOff = FeatherIcons.eyeOff;
  static const IconData visibility = FeatherIcons.eye;
  static const IconData search = FeatherIcons.search;
  
  // Validation status
  static const IconData checkCircle = FeatherIcons.checkCircle;
  static const IconData xCircle = FeatherIcons.xCircle;
  static const IconData error = FeatherIcons.alertCircle;
  
  // Audio and voice
  static const IconData volumeUp = FeatherIcons.volume2; // Speaker with high volume
  static const IconData volumeDown = FeatherIcons.volume1; // Speaker with low volume
  static const IconData volumeOff = FeatherIcons.volumeX; // Speaker with mute
  static const IconData speaker = FeatherIcons.volume2; // Alias for volumeUp
  static const IconData speaker2 = FeatherIcons.volume2; // Speaker-2 icon for Voice Guidance
  
  // Additional icons for Enhanced Home Screen
  static const IconData refresh = FeatherIcons.refreshCw;
  static const IconData target = FeatherIcons.target;
  static const IconData analytics = FeatherIcons.barChart;
  static const IconData security = FeatherIcons.shield;
  static const IconData count = FeatherIcons.hash;
}
