import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carento/core/theme/app_theme.dart';
import 'package:carento/firebase_options.dart';
import 'package:carento/features/auth/presentation/screens/splash_screen.dart';
import 'features/cars/presentation/screens/admin_seed_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Functions emulator
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);
    return MaterialApp(
      title: 'Drivana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        // Add localization delegates here
        // ...
      ],
      home: const SplashScreen(),
      routes: {
        '/admin-seed': (context) => const AdminSeedScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
