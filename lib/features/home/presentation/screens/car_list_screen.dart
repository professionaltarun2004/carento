import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carento/features/home/presentation/widgets/car_card.dart';
import 'package:carento/features/home/presentation/widgets/filter_sheet.dart';
import 'package:carento/core/constants/app_constants.dart';
import 'package:carento/features/cars/domain/models/car_model.dart';
import 'package:carento/features/cars/presentation/screens/car_details_screen.dart';
import 'package:carento/features/cars/data/services/car_recommendation_service.dart';
import 'package:geolocator/geolocator.dart';
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
  final CarRecommendationService _recommendationService = CarRecommendationService();
  List<CarModel> _recommendedCars = [];
  bool _isLoadingRecommendations = true;
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadRecommendations();
  }

  Future<void> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them to get better recommendations.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied. Recommendations will not be location-based.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. Please enable them in app settings.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _userLocation = GeoPoint(position.latitude, position.longitude);
      });
      _loadRecommendations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final recommendations = await _recommendationService.getRecommendedCars(
        userLocation: _userLocation,
      );
      setState(() {
        _recommendedCars = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() => _isLoadingRecommendations = false);
    }
  }

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
      stream: FirebaseFirestore.instance
          .collection(AppConstants.carsCollection)
          .where('available', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cars = snapshot.data?.docs ?? [];
        print('Loaded cars: \\${cars.length}');
        _updateMarkers(cars);

        if (cars.isEmpty && _recommendedCars.isEmpty) {
          return Center(child: Text('No cars available.'));
        }

        return RefreshIndicator(
          onRefresh: _loadRecommendations,
          child: ListView(
            children: [
              if (_recommendedCars.isNotEmpty)
                _buildSection(
                  context,
                  'Recommended for You',
                  _recommendedCars,
                  isLoading: _isLoadingRecommendations,
                ),
              _buildSection(
                context,
                'All Available Cars',
                cars.map((doc) => CarModel.fromFirestore(doc)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<dynamic> items, {
    bool isLoading = false,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final car = items[index] is CarModel
                ? items[index] as CarModel
                : CarModel.fromFirestore(items[index] as DocumentSnapshot);
            return CarCard(
              car: car,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarDetailsScreen(car: car),
                ),
              ),
            );
          },
        ),
      ],
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
            height: 80,
            child: GestureDetector(
              onTap: () {
                _mapController.move(
                  LatLng(carModel.location!.latitude, carModel.location!.longitude),
                  16.0,
                );
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(carModel.name ?? 'Car'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${carModel.isAvailable == true ? 'Available' : 'Booked'}'),
                        Text('Price: ₹${carModel.price?.toStringAsFixed(0) ?? 'N/A'}'),
                        if (carModel.isAvailable == false)
                          Row(
                            children: [
                              Icon(Icons.location_searching, color: Colors.green),
                              const SizedBox(width: 4),
                              Text('Tracking enabled'),
                            ],
                          ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
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
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Icon(Icons.directions_car, color: Colors.blue, size: 32),
                        if (carModel.isAvailable == false)
                          Icon(Icons.location_on, color: Colors.red, size: 18),
                      ],
                    ),
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
                  if (carModel.isAvailable == false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.track_changes, color: Colors.green, size: 18),
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