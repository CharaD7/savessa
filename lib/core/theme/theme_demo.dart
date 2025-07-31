import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'theme_toggle.dart';

/// This is a demo widget that showcases how to use the theme toggle components
/// in different parts of the app. This can be used as a reference for integrating
/// theme toggle functionality in the actual app.
class ThemeDemoScreen extends StatelessWidget {
  const ThemeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode from the provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode || 
                      (themeProvider.isSystemMode && 
                       MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Demo'),
        // Example of using ThemeToggleSwitch in AppBar actions
        actions: const [
          ThemeToggleSwitch(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display current theme information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Theme',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Mode', _getThemeModeName(themeProvider.themeMode)),
                    _buildInfoRow(context, 'System Dark Mode', 
                      MediaQuery.of(context).platformBrightness == Brightness.dark ? 'Yes' : 'No'),
                    _buildInfoRow(context, 'Effective Mode', isDarkMode ? 'Dark' : 'Light'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Example of using ThemeToggle (row of icons)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Toggle (Icon Row)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const Center(child: ThemeToggle()),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Example of using ThemeSettingTile in a settings screen
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const ThemeSettingTile(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Display color palette
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color Palette',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildColorPalette(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build info rows
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
  
  // Helper method to get theme mode name
  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  // Helper method to build color palette
  Widget _buildColorPalette(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildColorItem(context, 'Primary', colorScheme.primary),
        _buildColorItem(context, 'Primary Container', colorScheme.primaryContainer),
        _buildColorItem(context, 'Secondary', colorScheme.secondary),
        _buildColorItem(context, 'Secondary Container', colorScheme.secondaryContainer),
        _buildColorItem(context, 'Surface', colorScheme.surface),
        _buildColorItem(context, 'Background', colorScheme.surface),
        _buildColorItem(context, 'Error', colorScheme.error),
      ],
    );
  }
  
  // Helper method to build color item
  Widget _buildColorItem(BuildContext context, String label, Color color) {
    // Determine if text should be white or black based on color brightness
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}