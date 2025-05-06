import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carento/features/home/presentation/widgets/car_card.dart';
import 'package:carento/features/home/presentation/widgets/filter_sheet.dart';
import 'package:carento/core/constants/app_constants.dart';
import 'package:carento/features/cars/domain/models/car_model.dart';
import 'package:carento/features/cars/presentation/screens/car_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CarListScreen extends StatefulWidget {
  const CarListScreen({super.key});

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  bool _isMapView = false;
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  Map<String, dynamic> _filters = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Cars'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() => _isMapView = !_isMapView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => FilterSheet(
                  initialFilters: _filters,
                  onApply: (filters) {
                    setState(() => _filters = filters);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: _isMapView ? _buildMapView() : _buildListView(),
    );
  }

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredCarsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cars = snapshot.data?.docs ?? [];

        if (cars.isEmpty) {
          return const Center(
            child: Text('No cars available matching your criteria'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cars.length,
          itemBuilder: (context, index) {
            final carModel = CarModel.fromFirestore(cars[index]);
            return CarCard(
              car: carModel,
              onTap: () => _showCarDetails(context, carModel),
            );
          },
        );
      },
    );
  }

  Widget _buildMapView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredCarsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cars = snapshot.data?.docs ?? [];
        _updateMarkers(cars);

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(51.5, -0.09), // Default to London
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.carento',
            ),
            MarkerLayer(markers: _markers),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredCarsStream() {
    Query query = FirebaseFirestore.instance.collection(AppConstants.carsCollection);

    if (_filters.containsKey('fuelType')) {
      query = query.where('fuelType', isEqualTo: _filters['fuelType']);
    }
    if (_filters.containsKey('transmission')) {
      query = query.where('transmission', isEqualTo: _filters['transmission']);
    }
    if (_filters.containsKey('seats')) {
      query = query.where('seats', isEqualTo: _filters['seats']);
    }
    if (_filters.containsKey('minPrice')) {
      query = query.where('pricePerDay', isGreaterThanOrEqualTo: _filters['minPrice']);
    }
    if (_filters.containsKey('maxPrice')) {
      query = query.where('pricePerDay', isLessThanOrEqualTo: _filters['maxPrice']);
    }

    return query.snapshots();
  }

  void _updateMarkers(List<QueryDocumentSnapshot> cars) {
    _markers.clear();
    for (final car in cars) {
      final carModel = CarModel.fromFirestore(car);
      if (carModel.location != null) {
        _markers.add(
          Marker(
            point: LatLng(carModel.location!.latitude, carModel.location!.longitude),
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => _showCarDetails(context, carModel),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.directions_car, color: Colors.blue, size: 32),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${carModel.price?.toStringAsFixed(0) ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  void _showCarDetails(BuildContext context, CarModel car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarDetailsScreen(car: car),
      ),
    );
  }
}

Future<String> getGeminiResponse(String message) async {
  final url = 'https://<YOUR_REGION>-<YOUR_PROJECT>.cloudfunctions.net/geminiChat';
  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'message': message}),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['reply'] ?? 'No response from Gemini.';
  } else {
    return 'Error: ${response.body}';
  }
} 