import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carento/core/theme/app_theme.dart';
import 'package:carento/firebase_options.dart';
import 'package:carento/features/auth/presentation/screens/splash_screen.dart';
import 'package:carento/features/auth/presentation/screens/signup_screen.dart';
import 'features/cars/presentation/screens/admin_seed_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:carento/features/home/presentation/screens/home_screen.dart';
import 'package:carento/features/auth/presentation/screens/login_screen.dart';
import 'package:carento/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:carento/features/cars/domain/models/car_model.dart';
import 'features/cars/presentation/screens/car_details_screen.dart';
import 'package:carento/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:carento/core/services/notification_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Only use emulator in debug mode
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

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

    return MaterialApp.router(
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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/admin-seed',
      builder: (context, state) => const AdminSeedScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/car-details',
      builder: (context, state) {
        final car = state.extra as CarModel;
        return CarDetailsScreen(car: car);
      },
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
  ],
);

Future<String> getGeminiResponse(String prompt) async {
  final model = GenerativeModel(
      model: 'gemini-pro', apiKey: 'AIzaSyB7t7KatWmliVfyvtoj6BJJIZLLdYtHc-E');
  final content = [Content.text(prompt)];
  final response = await model.generateContent(content);
  return response.text ?? "No response from Gemini.";
}
