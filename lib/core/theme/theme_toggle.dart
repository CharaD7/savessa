import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  final bool showSystemOption;
  
  const ThemeToggle({
    super.key,
    this.showSystemOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Light theme icon button
            IconButton(
              icon: const Icon(Icons.light_mode),
              onPressed: () => themeProvider.setThemeMode(ThemeMode.light),
              color: themeProvider.isLightMode
                  ? Theme.of(context).colorScheme.primary
                  : null,
              tooltip: 'Light Theme',
            ),
            
            // System theme icon button (optional)
            if (showSystemOption)
              IconButton(
                icon: const Icon(Icons.brightness_auto),
                onPressed: () => themeProvider.setThemeMode(ThemeMode.system),
                color: themeProvider.isSystemMode
                    ? Theme.of(context).colorScheme.primary
                    : null,
                tooltip: 'System Theme',
              ),
            
            // Dark theme icon button
            IconButton(
              icon: const Icon(Icons.dark_mode),
              onPressed: () => themeProvider.setThemeMode(ThemeMode.dark),
              color: themeProvider.isDarkMode
                  ? Theme.of(context).colorScheme.primary
                  : null,
              tooltip: 'Dark Theme',
            ),
          ],
        );
      },
    );
  }
}

// A more compact version that can be used in app bars or other constrained spaces
class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode || 
                      (themeProvider.isSystemMode && 
                       MediaQuery.of(context).platformBrightness == Brightness.dark);
        
        return IconButton(
          icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          onPressed: () => themeProvider.toggleTheme(),
          tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
        );
      },
    );
  }
}

// A theme toggle that can be used in settings screens
class ThemeSettingTile extends StatelessWidget {
  const ThemeSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Theme',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              secondary: const Icon(Icons.light_mode),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              secondary: const Icon(Icons.dark_mode),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              secondary: const Icon(Icons.brightness_auto),
            ),
          ],
        );
      },
    );
  }
}