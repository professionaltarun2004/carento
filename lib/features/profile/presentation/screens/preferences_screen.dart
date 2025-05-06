import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Map<String, dynamic> _preferences = {
    'fuelType': 'Petrol',
    'transmission': 'Automatic',
    'seats': 5,
    'airConditioning': true,
    'priceRange': {'min': 1000, 'max': 5000},
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data()?['preferences'] != null) {
        setState(() {
          _preferences = Map<String, dynamic>.from(doc.data()?['preferences']);
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'preferences': _preferences,
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Preferences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePreferences,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPreferenceSection(
                    'Fuel Type',
                    DropdownButtonFormField<String>(
                      value: _preferences['fuelType'],
                      items: ['Petrol', 'Diesel', 'Electric', 'Hybrid']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _preferences['fuelType'] = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSection(
                    'Transmission',
                    DropdownButtonFormField<String>(
                      value: _preferences['transmission'],
                      items: ['Automatic', 'Manual']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _preferences['transmission'] = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSection(
                    'Number of Seats',
                    DropdownButtonFormField<int>(
                      value: _preferences['seats'],
                      items: [2, 4, 5, 7, 8]
                          .map((seats) => DropdownMenuItem(
                                value: seats,
                                child: Text('$seats seats'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _preferences['seats'] = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSection(
                    'Air Conditioning',
                    SwitchListTile(
                      value: _preferences['airConditioning'],
                      onChanged: (value) {
                        setState(() => _preferences['airConditioning'] = value);
                      },
                      title: const Text('Air Conditioning'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSection(
                    'Price Range',
                    Column(
                      children: [
                        RangeSlider(
                          values: RangeValues(
                            _preferences['priceRange']['min'].toDouble(),
                            _preferences['priceRange']['max'].toDouble(),
                          ),
                          min: 500,
                          max: 10000,
                          divisions: 19,
                          labels: RangeLabels(
                            '₹${_preferences['priceRange']['min']}',
                            '₹${_preferences['priceRange']['max']}',
                          ),
                          onChanged: (values) {
                            setState(() {
                              _preferences['priceRange'] = {
                                'min': values.start.round(),
                                'max': values.end.round(),
                              };
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${_preferences['priceRange']['min']}'),
                            Text('₹${_preferences['priceRange']['max']}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPreferenceSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
} 