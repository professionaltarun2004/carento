import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final languageProvider = StateProvider<Locale>((ref) => const Locale('en'));

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final currentLocale = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_getThemeName(currentTheme)),
            trailing: DropdownButton<ThemeMode>(
              value: currentTheme,
              items: ThemeMode.values.map((ThemeMode theme) {
                return DropdownMenuItem<ThemeMode>(
                  value: theme,
                  child: Text(_getThemeName(theme)),
                );
              }).toList(),
              onChanged: (ThemeMode? newTheme) {
                if (newTheme != null) {
                  ref.read(themeProvider.notifier).state = newTheme;
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_getLanguageName(currentLocale.languageCode)),
            trailing: DropdownButton<Locale>(
              value: currentLocale,
              items: const [
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: Locale('hi'),
                  child: Text('हिंदी'),
                ),
                DropdownMenuItem(
                  value: Locale('es'),
                  child: Text('Español'),
                ),
              ],
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  ref.read(languageProvider.notifier).state = newLocale;
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Notifications'),
            trailing: Switch(
              value: true, // TODO: Implement notification settings
              onChanged: (bool value) {
                // TODO: Implement notification toggle
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Carento',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
                children: const [
                  Text('A next-gen Car Rental App designed for scalability and real-time performance.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'es':
        return 'Español';
      default:
        return 'English';
    }
  }
} 