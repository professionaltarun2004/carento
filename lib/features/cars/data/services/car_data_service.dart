import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:carento/features/cars/domain/models/car_model.dart';

class CarDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> populateSampleCars() async {
    final cars = [
      {
        'name': 'Toyota Camry',
        'brand': 'Toyota',
        'model': 'Camry',
        'year': '2023',
        'price': 2500.0,
        'imageUrls': [
          'https://picsum.photos/800/600?random=1',
          'https://picsum.photos/800/600?random=2',
        ],
        'location': const GeoPoint(28.6139, 77.2090), // Delhi
        'ownerId': 'system',
        'specifications': {
          'transmission': 'Automatic',
          'fuelType': 'Petrol',
          'seats': 5,
          'luggage': '3 bags',
          'airConditioning': true,
        },
        'description': 'Comfortable and reliable sedan perfect for city driving.',
        'rating': 4.5,
        'totalRatings': 10,
      },
      {
        'name': 'Honda City',
        'brand': 'Honda',
        'model': 'City',
        'year': '2023',
        'price': 2200.0,
        'imageUrls': [
          'https://picsum.photos/800/600?random=3',
          'https://picsum.photos/800/600?random=4',
        ],
        'location': const GeoPoint(19.0760, 72.8777), // Mumbai
        'ownerId': 'system',
        'specifications': {
          'transmission': 'Manual',
          'fuelType': 'Diesel',
          'seats': 5,
          'luggage': '2 bags',
          'airConditioning': true,
        },
        'description': 'Fuel-efficient compact sedan with great handling.',
        'rating': 4.3,
        'totalRatings': 8,
      },
      {
        'name': 'Hyundai Creta',
        'brand': 'Hyundai',
        'model': 'Creta',
        'year': '2023',
        'price': 2800.0,
        'imageUrls': [
          'https://picsum.photos/800/600?random=5',
          'https://picsum.photos/800/600?random=6',
        ],
        'location': const GeoPoint(12.9716, 77.5946), // Bangalore
        'ownerId': 'system',
        'specifications': {
          'transmission': 'Automatic',
          'fuelType': 'Petrol',
          'seats': 5,
          'luggage': '4 bags',
          'airConditioning': true,
        },
        'description': 'Stylish SUV with modern features and comfortable ride.',
        'rating': 4.7,
        'totalRatings': 15,
      },
    ];

    for (var car in cars) {
      await _firestore.collection('cars').add(car);
    }
  }

  Future<List<String>> uploadCarImages(String carId, List<String> imagePaths) async {
    final List<String> uploadedUrls = [];
    
    for (var i = 0; i < imagePaths.length; i++) {
      final ref = _storage.ref().child('cars/$carId/${i + 1}.jpg');
      // TODO: Implement actual image upload
      // For now, we'll use placeholder URLs
      uploadedUrls.add('https://picsum.photos/800/600?random=${DateTime.now().millisecondsSinceEpoch}');
    }
    
    return uploadedUrls;
  }

  Stream<List<CarModel>> getCars() {
    return _firestore
        .collection('cars')
        .orderBy('price')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CarModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addCar(CarModel car) async {
    await _firestore.collection('cars').add(car.toMap());
  }

  Future<void> updateCar(String carId, Map<String, dynamic> data) async {
    await _firestore.collection('cars').doc(carId).update(data);
  }

  Future<void> deleteCar(String carId) async {
    await _firestore.collection('cars').doc(carId).delete();
  }
} 