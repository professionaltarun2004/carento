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

    // Extract car IDs from bookings
    final bookedCarIds = bookings.docs
        .map((doc) => doc.data()['carId'] as String)
        .toSet();

    // Get all available cars
    final carsSnapshot = await _firestore
        .collection('cars')
        .where('isAvailable', isEqualTo: true)
        .get();

    final cars = carsSnapshot.docs
        .map((doc) => CarModel.fromFirestore(doc))
        .where((car) => !bookedCarIds.contains(car.id))
        .toList();

    // Calculate scores for each car
    final scoredCars = cars.map((car) {
      double score = 0.0;
      final weights = {
        'price': 0.3,
        'location': 0.2,
        'features': 0.2,
        'ratings': 0.15,
        'recency': 0.15,
      };

      // Price range scoring (prefer cars in similar price range to previously booked cars)
      if (bookings.docs.isNotEmpty) {
        final avgBookedPrice = bookings.docs
            .map((doc) => doc.data()['totalAmount'] as double)
            .reduce((a, b) => a + b) /
            bookings.docs.length;
        
        final priceDiff = (car.price ?? 0) - avgBookedPrice;
        final priceScore = 1.0 - (priceDiff.abs() / (avgBookedPrice * 2)).clamp(0.0, 1.0);
        score += priceScore * weights['price']!;
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

      // Feature matching (prefer cars with similar features to previously booked cars)
      if (bookings.docs.isNotEmpty) {
        final bookedSpecs = bookings.docs
            .map((doc) => doc.data()['specifications'] as Map<String, dynamic>)
            .toList();

        double featureScore = 0.0;
        for (final spec in bookedSpecs) {
          if (car.specifications != null) {
            for (final key in spec.keys) {
              if (car.specifications!.containsKey(key) &&
                  car.specifications![key] == spec[key]) {
                featureScore += 0.5;
              }
            }
          }
        }
        featureScore = (featureScore / bookedSpecs.length).clamp(0.0, 1.0);
        score += featureScore * weights['features']!;
      }

      // User preferences matching
      if (userPreferences.isNotEmpty && car.specifications != null) {
        double preferenceScore = 0.0;
        for (final key in userPreferences.keys) {
          if (car.specifications!.containsKey(key) &&
              car.specifications![key] == userPreferences[key]) {
            preferenceScore += 0.5;
          }
        }
        preferenceScore = (preferenceScore / userPreferences.length).clamp(0.0, 1.0);
        score += preferenceScore * 0.1; // Additional weight for user preferences
      }

      // Rating scoring
      final ratingScore = (car.rating ?? 0) / 5.0;
      score += ratingScore * weights['ratings']!;

      // Recency scoring (prefer newer cars)
      if (car.year != null) {
        final currentYear = DateTime.now().year;
        final carYear = int.tryParse(car.year!) ?? currentYear;
        final recencyScore = 1.0 - ((currentYear - carYear) / 10).clamp(0.0, 1.0);
        score += recencyScore * weights['recency']!;
      }

      return {
        'car': car,
        'score': score,
        'details': {
          'priceScore': score * weights['price']!,
          'locationScore': score * weights['location']!,
          'featureScore': score * weights['features']!,
          'ratingScore': score * weights['ratings']!,
          'recencyScore': score * weights['recency']!,
        },
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