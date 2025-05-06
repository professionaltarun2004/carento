import 'package:flutter/material.dart';
import '../../data/services/car_data_service.dart';

class AdminSeedScreen extends StatefulWidget {
  const AdminSeedScreen({Key? key}) : super(key: key);

  @override
  State<AdminSeedScreen> createState() => _AdminSeedScreenState();
}

class _AdminSeedScreenState extends State<AdminSeedScreen> {
  bool _isLoading = false;
  String? _result;

  Future<void> _seedCars() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });
    try {
      await CarDataService().populateSampleCars();
      setState(() {
        _result = 'Sample cars seeded successfully!';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Seed Cars')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _seedCars,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Seed Sample Cars'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 24),
                Text(_result!, style: TextStyle(color: _result!.startsWith('Error') ? Colors.red : Colors.green)),
              ]
            ],
          ),
        ),
      ),
    );
  }
} 