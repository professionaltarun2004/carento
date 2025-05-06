import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:carento/features/auth/presentation/screens/login_screen.dart';
import 'package:carento/features/home/presentation/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthState();
      }
    });

    _controller.forward();
  }

  Future<void> _checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => user != null 
          ? const HomeScreen() 
          : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/car_loading.json',
              controller: _controller,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Drivana',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Premium Car Rental Experience',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 