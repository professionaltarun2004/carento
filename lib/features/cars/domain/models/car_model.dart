import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CarModel {
  final String? id;
  final String? name;
  final String? brand;
  final String? type;
  final String? imageUrl;
  final List<String>? imageUrls;
  final double? price;
  final double? rating;
  final double? distance;
  final bool? isAvailable;
  final String? description;
  final List<String>? features;
  final Map<String, dynamic>? specifications;
  final String? city;
  final String? carType;

  CarModel({
    this.id,
    this.name,
    this.brand,
    this.type,
    this.imageUrl,
    this.imageUrls,
    this.price,
    this.rating,
    this.distance,
    this.isAvailable,
    this.description,
    this.features,
    this.specifications,
    this.city,
    this.carType,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      type: json['type'] as String?,
      imageUrl: json['imageUrl'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      price: (json['price'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] as bool?,
      description: json['description'] as String?,
      features: (json['features'] as List<dynamic>?)?.map((e) => e as String).toList(),
      specifications: json['specifications'] as Map<String, dynamic>?,
      city: json['city'] as String?,
      carType: json['carType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'type': type,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'price': price,
      'rating': rating,
      'distance': distance,
      'isAvailable': isAvailable,
      'description': description,
      'features': features,
      'specifications': specifications,
      'city': city,
      'carType': carType,
    };
  }

  factory CarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CarModel(
      id: doc.id,
      name: data['name'] ?? 'Car Name',
      brand: data['brand'] as String?,
      type: data['type'] as String?,
      imageUrl: data['imageUrl'] as String?,
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : null,
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      distance: (data['distance'] is num) ? (data['distance'] as num).toDouble() : null,
      isAvailable: data['isAvailable'] ?? data['available'] ?? true,
      description: data['description'] ?? '',
      features: (data['features'] as List<dynamic>?)?.map((e) => e as String).toList(),
      specifications: data['specifications'] ?? {},
      city: data['city'] as String?,
      carType: data['carType'] as String?,
    );
  }

  get year => null;

  get location => null;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'type': type,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'price': price,
      'rating': rating,
      'distance': distance,
      'isAvailable': isAvailable,
      'description': description,
      'features': features,
      'specifications': specifications,
      'city': city,
      'carType': carType,
    };
  }

  Future<double> getDistanceFromCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (distance == null) return -1;
      return distance!;
    } catch (e) {
      return -1; // Return -1 if distance is not available
    }
  }
} 