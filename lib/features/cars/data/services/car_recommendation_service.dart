import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/car_model.dart';

class CarRecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<CarModel>> getRecommendedCars({
    int limit = 5,
    GeoPoint? userLocation,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // Get user's booking history
    final bookings = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    // Get user's preferences from profile
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userPreferences = userDoc.data()?['preferences'] as Map<String, dynamic>? ?? {};

    // Extract car IDs and favorite city/type from bookings
    final bookedCarIds = bookings.docs.map((doc) => doc.data()['carId'] as String).toSet();
    final favoriteCity = bookings.docs.isNotEmpty
        ? (bookings.docs
            .map((doc) => doc.data()['city'] ?? '')
            .fold<Map<String, int>>({}, (map, city) {
              map[city] = (map[city] ?? 0) + 1;
              return map;
            })
            .entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key)
        : null;
    final favoriteType = bookings.docs.isNotEmpty
        ? (bookings.docs
            .map((doc) => doc.data()['carType'] ?? '')
            .fold<Map<String, int>>({}, (map, type) {
              map[type] = (map[type] ?? 0) + 1;
              return map;
            })
            .entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key)
        : null;

    // Get all available cars
    final carsSnapshot = await _firestore
        .collection('cars')
        .where('available', isEqualTo: true)
        .get();

    final cars = carsSnapshot.docs
        .map((doc) => CarModel.fromFirestore(doc))
        .where((car) => !bookedCarIds.contains(car.id))
        .toList();

    // If user has no history, show top-rated or trending cars
    if (bookings.docs.isEmpty) {
      cars.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      return cars.take(limit).toList();
    }

    // Calculate scores for each car
    final scoredCars = cars.map((car) {
      double score = 0.0;
      final weights = {
        'preference': 0.25,
        'city': 0.2,
        'type': 0.2,
        'rating': 0.15,
        'recency': 0.1,
        'location': 0.1,
      };

      // User preferences matching
      if (userPreferences.isNotEmpty && car.specifications != null) {
        double preferenceScore = 0.0;
        for (final key in userPreferences.keys) {
          if (car.specifications!.containsKey(key) &&
              car.specifications![key] == userPreferences[key]) {
            preferenceScore += 1.0;
          }
        }
        preferenceScore = (preferenceScore / userPreferences.length).clamp(0.0, 1.0);
        score += preferenceScore * weights['preference']!;
      }

      // City matching
      if (favoriteCity != null && car.city != null && car.city == favoriteCity) {
        score += 1.0 * weights['city']!;
      }

      // Car type matching
      if (favoriteType != null && car.carType != null && car.carType == favoriteType) {
        score += 1.0 * weights['type']!;
      }

      // Rating scoring
      final ratingScore = (car.rating ?? 0) / 5.0;
      score += ratingScore * weights['rating']!;

      // Recency scoring (prefer newer cars)
      if (car.year != null) {
        final currentYear = DateTime.now().year;
        final carYear = int.tryParse(car.year!) ?? currentYear;
        final recencyScore = 1.0 - ((currentYear - carYear) / 10).clamp(0.0, 1.0);
        score += recencyScore * weights['recency']!;
      }

      // Location scoring (prefer cars closer to user's location)
      if (userLocation != null && car.location != null) {
        final distance = const Distance().as(
          LengthUnit.Kilometer,
          LatLng(userLocation.latitude, userLocation.longitude),
          LatLng(car.location!.latitude, car.location!.longitude),
        );
        final locationScore = 1.0 - (distance / 50).clamp(0.0, 1.0);
        score += locationScore * weights['location']!;
      }

      return {
        'car': car,
        'score': score,
      };
    }).toList();

    // Sort by score and return top recommendations
    scoredCars.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return scoredCars
        .take(limit)
        .map((scoredCar) => scoredCar['car'] as CarModel)
        .toList();
  }
} 