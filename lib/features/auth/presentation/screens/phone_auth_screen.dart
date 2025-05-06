import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carento/features/home/presentation/screens/home_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Verification failed')),
          );
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone verification failed')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null) return;

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_codeSent) ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+1234567890',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!value.startsWith('+')) {
                        return 'Phone number must start with country code (e.g., +1)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPhone,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Send OTP'),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the OTP';
                      }
                      if (value.length < 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Verify OTP'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _verifyPhone,
                    child: const Text('Resend OTP'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 