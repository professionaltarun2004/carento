import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CarModel {
  final String? id;
  final String? name;
  final String? brand;
  final String? model;
  final String? year;
  final double? price;
  final List<String>? imageUrls;
  final GeoPoint? location;
  final String? ownerId;
  final bool? isAvailable;
  final Map<String, dynamic>? specifications;
  final String? description;
  final double? rating;
  final int? totalRatings;

  CarModel({
    this.id,
    this.name,
    this.brand,
    this.model,
    this.year,
    this.price,
    this.imageUrls,
    this.location,
    this.ownerId,
    this.isAvailable = true,
    this.specifications,
    this.description,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  factory CarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CarModel(
      id: doc.id,
      name: data['name'] ?? 'Car Name',
      brand: data['brand'] ?? 'N/A',
      model: data['model'] ?? 'N/A',
      year: data['year'] ?? 'N/A',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : null,
      imageUrls: (data['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      location: data['location'] is GeoPoint ? data['location'] : null,
      ownerId: data['ownerId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      specifications: data['specifications'] ?? {},
      description: data['description'] ?? '',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      totalRatings: data['totalRatings'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'model': model,
      'year': year,
      'price': price,
      'imageUrls': imageUrls,
      'location': location,
      'ownerId': ownerId,
      'isAvailable': isAvailable,
      'specifications': specifications,
      'description': description,
      'rating': rating,
      'totalRatings': totalRatings,
    };
  }

  Future<double> getDistanceFromCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (location == null) return -1;
      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location!.latitude,
        location!.longitude,
      );
    } catch (e) {
      return -1; // Return -1 if location is not available
    }
  }
} 