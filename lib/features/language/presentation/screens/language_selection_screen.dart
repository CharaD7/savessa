import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/core/constants/icon_mapping.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  // Track the currently hovered language card
  String? _hoveredLanguage;
  
  // Track if voice guidance is enabled
  bool _voiceGuidanceEnabled = false;
  
  // List of supported languages with their codes and names
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'sw', 'name': 'Kiswahili'},
    {'code': 'yo', 'name': 'Yorùbá'},
    {'code': 'ha', 'name': 'Hausa'},
  ];

  // Play hover sound (to be implemented with actual sound assets)
  void _playHoverSound() {
    // TODO: Implement sound playback when assets are available
    debugPrint('Playing hover sound');
  }

  // Play selection sound (to be implemented with actual sound assets)
  void _playSelectionSound() {
    // TODO: Implement sound playback when assets are available
    debugPrint('Playing selection sound');
  }

  // Play voice guidance (to be implemented with actual sound assets)
  void _playVoiceGuidance(String languageCode) {
    if (!_voiceGuidanceEnabled) return;
    
    // TODO: Implement voice guidance playback when assets are available
    debugPrint('Playing voice guidance for $languageCode');
  }

  // Select language and navigate to onboarding
  void _selectLanguage(BuildContext context, String languageCode) async {
    _playSelectionSound();
    
    // Set the app locale
    await context.setLocale(Locale(languageCode));
    
    // Navigate to onboarding screen
    if (context.mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Choose Your Language',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your preferred language to continue',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Voice guidance toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconMapping.speaker2, // Using speaker-2 icon for Voice Guidance
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voice Guidance',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: _voiceGuidanceEnabled,
                      onChanged: (value) {
                        setState(() {
                          _voiceGuidanceEnabled = value;
                        });
                      },
                      activeThumbColor: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              
              // Language cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final language = _languages[index];
                      final isHovered = _hoveredLanguage == language['code'];
                      
                      return MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            _hoveredLanguage = language['code'];
                          });
                          _playHoverSound();
                          _playVoiceGuidance(language['code']!);
                        },
                        onExit: (_) {
                          setState(() {
                            _hoveredLanguage = null;
                          });
                        },
                        child: GestureDetector(
                          onTap: () => _selectLanguage(context, language['code']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isHovered 
                                ? theme.colorScheme.secondary 
                                : theme.colorScheme.onPrimary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isHovered
                                    ? AppTheme.gold.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.1),
                                  blurRadius: isHovered ? 12 : 4,
                                  spreadRadius: isHovered ? 2 : 0,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Flag image using SVG
                                Container(
                                  width: 60,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 2,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: SvgPicture.asset(
                                    'assets/icons/flags/${language['code']}.svg',
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 40,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  language['name']!,
                                  style: TextStyle(
                                    color: isHovered 
                                      ? theme.colorScheme.onSecondary 
                                      : theme.colorScheme.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}